---@meta _
---@diagnostic disable: duplicate-doc-field

---Update MinimapLocation
local function UpdateMinimapLocation()
    if VFW.HudLayout and VFW.HudLayout.ApplyMinimap then
        VFW.HudLayout.ApplyMinimap(true)
        return
    end

    local ratio <const> = GetScreenAspectRatio()
    local posX = -0.0045
    local posY = 0.012

    if tonumber(string.format("%.2f", ratio)) >= 2.3 then
        posX = -0.17
    end

    SetMinimapComponentPosition('minimap', 'L', 'B', posX, posY, 0.150, 0.188888)
    SetMinimapComponentPosition('minimap_mask', 'L', 'B', posX + 0.0155, posY + 0.03, 0.111, 0.159)
    SetMinimapComponentPosition('minimap_blur', 'L', 'B', posX - 0.0255, posY + 0.02, 0.266, 0.237)

    DisplayRadar(false)
    SetRadarBigmapEnabled(true, false)

    Wait(0)

    SetRadarBigmapEnabled(false, false)
    DisplayRadar(true)

    SetRadarZoom(1200)
end

local customWeaponAmmo = {
    ["WEAPON_AR15"] = "ammo_rifle",
    ["WEAPON_HK416"] = "ammo_rifle",
    ["WEAPON_KS1"] = "ammo_rifle",
    ["WEAPON_M4A1CD"] = "ammo_rifle",
    ["WEAPON_GLOCK20"] = "ammo_pistol",
    ["WEAPON_PDGLOCK17"] = "ammo_pistol",
    ["WEAPON_SIG_SAUCER"] = "ammo_pistol",
    ["WEAPON_SWMP9L"] = "ammo_pistol",
    ["WEAPON_PDPT700"] = "ammo_heavy",
}

local function GetAmmoItemForWeapon(weaponName)
    weaponName = weaponName:upper()

    if customWeaponAmmo[weaponName] then return customWeaponAmmo[weaponName] end

    if string.find(weaponName, "AIRSOFT") then return "ammo_airsoft" end
    if string.find(weaponName, "BEANBAG") then return "ammo_beanbag" end
    if string.find(weaponName, "MUSKET") then return "ammo_musquet" end
    if string.find(weaponName, "FLAREGUN") then return "ammo_flare" end

    if string.find(weaponName, "COMPACTLAUNCHER") or string.find(weaponName, "HOMINGLAUNCHER") then return "ammo_rocket" end
    if string.find(weaponName, "LAUNCHER") or string.find(weaponName, "RPG") or string.find(weaponName, "FIREWORK") then return "ammo_launcher" end

    if string.find(weaponName, "COMBATMG") or weaponName == "WEAPON_MG" or string.find(weaponName, "MINIGUN") or string.find(weaponName, "RAILGUN") or string.find(weaponName, "HEAVYSNIPER") then return "ammo_heavy" end

    if string.find(weaponName, "MARKSMANRIFLE") or string.find(weaponName, "PRECISIONRIFLE") or string.find(weaponName, "SNIPERRIFLE") then return "ammo_snip" end

    if string.find(weaponName, "PISTOL") or string.find(weaponName, "REVOLVER") then return "ammo_pistol" end

    if string.find(weaponName, "SMG") or string.find(weaponName, "PDW") or string.find(weaponName, "GUSENBERG") or string.find(weaponName, "RAYCARBINE") then return "ammo_rifle" end

    if string.find(weaponName, "RIFLE") then return "ammo_rifle" end

    if string.find(weaponName, "SHOTGUN") then return "ammo_shotgun" end

    return nil
end

---Load Hud
local function LoadHud()
    UpdateMinimapLocation()
    VFW.Nui.HudVisible(true)

    while true do
        local weaponData = {
            visible = false,
            weapon = "",
            bullets = 0,
            maxBullets = 0,
            totalAmmo = 0,
            unlimited = false
        }

        if IsPedArmed(VFW.PlayerData.ped, 4) then
            if VFW.PlayerData.weapon then
                local weaponInfo = VFW.GetWeaponFromHash(VFW.PlayerData.weapon)

                if weaponInfo and weaponInfo.name then
                    weaponData.visible = true
                    weaponData.weapon = string.lower(weaponInfo.name)

                    local maxClip = (VFW.GetReliableMaxClip and VFW.GetReliableMaxClip(VFW.PlayerData.ped, VFW.PlayerData.weapon))
                                    or GetMaxAmmoInClip(VFW.PlayerData.ped, VFW.PlayerData.weapon, true)
                                    or 0
                    weaponData.maxBullets = maxClip

                    if maxClip > 0 then
                        local bulletsInClip = (VFW.GetReliableClipAmmo and VFW.GetReliableClipAmmo(VFW.PlayerData.ped, VFW.PlayerData.weapon))
                                              or (select(2, GetAmmoInClip(VFW.PlayerData.ped, VFW.PlayerData.weapon)))
                                              or 0

                        weaponData.bullets = math.min(bulletsInClip, maxClip)
                    else
                        weaponData.visible = false
                    end

                    local itemData = VFW.Items[weaponData.weapon]
                    local ammoType = itemData and itemData.data and itemData.data.ammoType or GetAmmoItemForWeapon(weaponInfo.name)
                    if ammoType and VFW.PlayerData.inventory then
                        local total = 0
                        for i = 1, #VFW.PlayerData.inventory do
                            if VFW.PlayerData.inventory[i].name == ammoType then
                                total = total + VFW.PlayerData.inventory[i].count
                            end
                        end
                        weaponData.totalAmmo = total
                    else
                        weaponData.unlimited = true
                    end
                end
            end
        end

        SendNUIMessage({
            action = "nui:weapon:data",
            data = weaponData
        })

        Wait(250)
    end
end

RegisterNetEvent("LoadHud", LoadHud)

local lastType = 2

---Handle MicrophoneAction (DISABLED - Using text display instead)
---@param visible boolean
local function HandleMicrophoneAction(visible)
    -- Disabled: Microphone UI removed, using text display at bottom right instead
    -- SendNUIMessage({
    --     action = "nui:hud:visible:microphone",
    --     data = {
    --         visible = visible,
    --         type = lastType,
    --     }
    -- })
end

-- Thread disabled - No longer showing microphone UI
-- CreateThread(function()
--     while true do
--         HandleMicrophoneAction(NetworkIsPlayerTalking(VFW.playerId))
--         Wait(250)
--     end
-- end)

---@param type any
AddEventHandler("pma-voice:setTalkingMode", function(type)
    lastType = type
    -- HandleMicrophoneAction(true, lastType) -- Disabled: Using text display instead
end)

--- isVehAllowed
---@return boolean
local function isVehAllowed()
    if VFW.PlayerData.seat ~= -1 or GetVehicleClass(VFW.PlayerData.vehicle) ~= 18 or IsPedInAnyHeli(VFW.PlayerData.vehicle) or IsPedInAnyPlane(VFW.PlayerData.vehicle) then
        return false
    end

    return true
end

local state = false

--- Thread
---@param veh any
---@param seat any
local function Thread(veh, seat)
    CreateThread(function()
        while state do
            if veh ~= 0 and DoesEntityExist(veh) and (seat == -1 or seat == 0) then
                local shouldUseMetric = ShouldUseMetricMeasurements()
                local speed = math.ceil(GetEntitySpeed(veh) * (shouldUseMetric and 3.6 or 2.236936))
                local _, positionLight, roadLight = GetVehicleLightsState(veh)
                local fuel = GetVehicleFuelLevel(veh)
                local health = GetVehicleEngineHealth(veh) / 10
                local indicator = GetVehicleIndicatorLights(VFW.PlayerData.vehicle)
                local sirenState = Entity(VFW.PlayerData.vehicle).state
                
                SendNUIMessage({
                    action = "nui:speedometer:visible",
                    data = {
                        visible = true,
                        fuelState = fuel,
                        speedState = speed,
                        motorState = health,
                        HeadlightTop = roadLight,
                        HeadlightBottom = positionLight,
                        TursignalLeft = (indicator == 1 or indicator == 3),
                        TursignalRight = (indicator == 2 or indicator == 3),
                        isSiren = sirenState.lightsOn,
                        isSirenSound = sirenState.sirenMode,
                        is911 = isVehAllowed(),
                    }
                })
            else
                if not (VFW.HudLayout and VFW.HudLayout.IsEditing and VFW.HudLayout.IsEditing()) then
                    SendNUIMessage({
                        action = "nui:speedometer:visible",
                        data = { visible = false }
                    })
                end
            end

            Wait(100)
        end
    end)
end

---@param vehicle any
---@param _ any
---@param seat any
AddEventHandler("vfw:enteredVehicle", function(vehicle, _, seat)
    if state then
        return
    end

    state = true
    Thread(vehicle, seat)
end)

AddEventHandler("vfw:exitedVehicle", function()
    state = false
    if VFW.HudLayout and VFW.HudLayout.IsEditing and VFW.HudLayout.IsEditing() then
        return
    end
    SendNUIMessage({
        action = "nui:speedometer:visible",
        data = { visible = false }
    })
end)

RegisterKeyMapping('+leftIndicator', 'Clignotant gauche', 'keyboard', 'LEFT')
RegisterCommand('+leftIndicator', function()
    if not VFW.PlayerData.vehicle then
        return
    end

    if VFW.PlayerData.seat ~= -1 then
        return
    end

    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 1, not (GetVehicleIndicatorLights(VFW.PlayerData.vehicle) == 1))
    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 0, false)
end)

RegisterKeyMapping('+rightIndicator', 'Clignotant droit', 'keyboard', 'RIGHT')
RegisterCommand('+rightIndicator', function()
    if not VFW.PlayerData.vehicle then
        return
    end

    if VFW.PlayerData.seat ~= -1 then
        return
    end

    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 0, not (GetVehicleIndicatorLights(VFW.PlayerData.vehicle) == 2))
    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 1, false)
end)

RegisterKeyMapping('+hazardIndicator', 'Warning Véhicule', 'keyboard', 'UP')
RegisterCommand('+hazardIndicator', function()
    if not VFW.PlayerData.vehicle then
        return
    end

    if VFW.PlayerData.seat ~= -1 then
        return
    end

    local indicator = GetVehicleIndicatorLights(VFW.PlayerData.vehicle)
    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 1, not (indicator == 3))
    SetVehicleIndicatorLights(VFW.PlayerData.vehicle, 0, not (indicator == 3))
end)

CreateThread(function()
    while true do
        DisableControlAction(0, 199, true)
        Wait(0)
    end
end)

