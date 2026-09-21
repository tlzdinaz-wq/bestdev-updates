---@meta _
---@diagnostic disable: duplicate-doc-field

---@class Adjustments
Adjustments = {}

--- Removes HUD components based on the configuration.
function Adjustments:RemoveHudComponents()
    for i = 1, #Config.RemoveHudComponents do
        if Config.RemoveHudComponents[i] then
            SetHudComponentSize(i, 0.0, 0.0)
            SetHudComponentPosition(i, 900, 900)
        end
    end
end

--- Disables aim assist for the player.
function Adjustments:DisableAimAssist()
    SetPlayerTargetingMode(3)
end

--- Disables NPC weapon drops.
function Adjustments:DisableNPCDrops()
    local weaponPickups = {
        `PICKUP_WEAPON_CARBINERIFLE`, `PICKUP_WEAPON_PISTOL`,
        `PICKUP_WEAPON_PUMPSHOTGUN`
    }

    for i = 1, #weaponPickups do
        ToggleUsePickupsForPlayer(VFW.playerId, weaponPickups[i], false)
    end
end

--- Handles seat shuffling when entering a vehicle.
function Adjustments:SeatShuffle()
---@param vehicle any
---@param _ any
---@param seat any
    AddEventHandler("vfw:enteredVehicle", function(vehicle, _, seat)
        if seat > -1 then
            SetPedIntoVehicle(VFW.PlayerData.ped, vehicle, seat)
            SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
        end
    end)
end

--- Disables health regeneration for the player.
function Adjustments:HealthRegeneration()
    SetPlayerHealthRechargeMultiplier(VFW.playerId, 0.0)
end

--- Disables ammo and vehicle rewards for the player.
function Adjustments:AmmoAndVehicleRewards()
    CreateThread(function()
        while true do
            DisablePlayerVehicleRewards(VFW.playerId)
            Wait(0)
        end
    end)
end

--- Enables PvP mode for the player.
function Adjustments:EnablePvP()
    SetCanAttackFriendly(VFW.PlayerData.ped, true, false)
    NetworkSetFriendlyFireOption(true)
end

--- Disables dispatch services.
function Adjustments:DispatchServices()
    for i = 1, 15 do
        EnableDispatchService(i, false)
    end

    SetAudioFlag('PoliceScannerDisabled', true)
end

--- Disables ambient gunshot sounds at Ammunation locations.
function Adjustments:DisableAmmunationGunshots()
    -- Static emitters des stands de tir indoor de chaque Ammunation
    local emitters = {
        "SE_ammu_school_gun_range_01",
        "SE_ammu_school_gun_range_02",
        "SE_ammu_school_gun_range_03",
        "SE_ammu_school_gun_range_04",
        "SE_ammu_school_gun_range_05",
        "SE_ammu_school_gun_range_06",
        "SE_ammu_school_gun_range_07",
        "SE_ammu_school_gun_range_08",
        "SE_ammu_school_gun_range_09",
        "SE_AMM_Shooting_Range_01_Range_Sounds",
        "SE_AMM_Shooting_Range_02_Range_Sounds",
        "SE_AMM_Shooting_Range_03_Range_Sounds",
        "SE_AMM_Shooting_Range_04_Range_Sounds",
        "SE_AMM_Shooting_Range_05_Range_Sounds",
    }
    for i = 1, #emitters do
        SetStaticEmitterEnabled(emitters[i], false)
    end

    -- Ambient zones (random/distant gunfire + range ambience)
    local zones = {
        "AZ_DISTANT_GUNFIRE",
        "AMBIENT_GUNFIRE_DISTANT",
        "AZ_LSGUNRANGE_LARGE_RANGE",
        "AZ_LSGUNRANGE_SMALL_RANGE",
        "collision_ybmrar",
    }
    for i = 1, #zones do
        SetAmbientZoneState(zones[i], false, false)
    end
end

--- Disables specific NPC scenarios.
function Adjustments:NPCScenarios()
    local scenarios = {
        "WORLD_VEHICLE_ATTRACTOR", "WORLD_VEHICLE_AMBULANCE",
        "WORLD_VEHICLE_BICYCLE_BMX", "WORLD_VEHICLE_BICYCLE_BMX_BALLAS",
        "WORLD_VEHICLE_BICYCLE_BMX_FAMILY", "WORLD_VEHICLE_BICYCLE_BMX_HARMONY",
        "WORLD_VEHICLE_BICYCLE_BMX_VAGOS", "WORLD_VEHICLE_BICYCLE_MOUNTAIN",
        "WORLD_VEHICLE_BICYCLE_ROAD", "WORLD_VEHICLE_BIKE_OFF_ROAD_RACE",
        "WORLD_VEHICLE_BIKER", "WORLD_VEHICLE_BOAT_IDLE",
        "WORLD_VEHICLE_BOAT_IDLE_ALAMO", "WORLD_VEHICLE_BOAT_IDLE_MARQUIS",
        "WORLD_VEHICLE_BOAT_IDLE_MARQUIS", "WORLD_VEHICLE_BROKEN_DOWN",
        "WORLD_VEHICLE_BUSINESSMEN", "WORLD_VEHICLE_HELI_LIFEGUARD",
        "WORLD_VEHICLE_CLUCKIN_BELL_TRAILER", "WORLD_VEHICLE_CONSTRUCTION_SOLO",
        "WORLD_VEHICLE_CONSTRUCTION_PASSENGERS",
        "WORLD_VEHICLE_DRIVE_PASSENGERS",
        "WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED", "WORLD_VEHICLE_DRIVE_SOLO",
        "WORLD_VEHICLE_FIRE_TRUCK", "WORLD_VEHICLE_EMPTY",
        "WORLD_VEHICLE_MARIACHI", "WORLD_VEHICLE_MECHANIC",
        "WORLD_VEHICLE_MILITARY_PLANES_BIG",
        "WORLD_VEHICLE_MILITARY_PLANES_SMALL", "WORLD_VEHICLE_PARK_PARALLEL",
        "WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN",
        "WORLD_VEHICLE_PASSENGER_EXIT", "WORLD_VEHICLE_POLICE_BIKE",
        "WORLD_VEHICLE_POLICE_CAR", "WORLD_VEHICLE_POLICE",
        "WORLD_VEHICLE_POLICE_NEXT_TO_CAR", "WORLD_VEHICLE_QUARRY",
        "WORLD_VEHICLE_SALTON", "WORLD_VEHICLE_SALTON_DIRT_BIKE",
        "WORLD_VEHICLE_SECURITY_CAR", "WORLD_VEHICLE_STREETRACE",
        "WORLD_VEHICLE_TOURBUS", "WORLD_VEHICLE_TOURIST", "WORLD_VEHICLE_TANDL",
        "WORLD_VEHICLE_TRACTOR", "WORLD_VEHICLE_TRACTOR_BEACH",
        "WORLD_VEHICLE_TRUCK_LOGS", "WORLD_VEHICLE_TRUCKS_TRAILERS",
        "WORLD_VEHICLE_DISTANT_EMPTY_GROUND", "WORLD_HUMAN_PAPARAZZI"
    }

    for i = 1, #scenarios do
        SetScenarioTypeEnabled(scenarios[i], false)
    end
end

--- Sets custom license plates for AI vehicles.
function Adjustments:LicensePlates()
    SetDefaultVehicleNumberPlateTextPattern(-1, Config.CustomAIPlates)
end

local placeHolders = {
    server_name = function()
        if VFW and VFW.BrandName then
            return VFW.BrandName()
        end
        return GetConvar("core_brand_name", GetConvar("sv_projectName", "VFW-Framework"))
    end,
    server_endpoint = function()
        return GetCurrentServerEndpoint() or "localhost:30120"
    end,
    server_players = function() return GlobalState.playerCount or 0 end,
    server_maxplayers = function() return GetConvarInt("sv_maxclients", 500) end,
    player_name = function() return GetPlayerName(VFW.playerId) end,
    player_rp_name = function() return VFW.PlayerData.name or "John Doe" end,
    player_id = function() return Player(VFW.serverId).state.id end,
    player_street = function()
        if not VFW.PlayerData.ped then
            return "Unknown"
        end

        local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
        local streetHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y,
                                                playerCoords.z)

        return GetStreetNameFromHashKey(streetHash) or "Unknown"
    end
}

--- Replaces placeholders in the Discord presence string.
--- @return string The presence string with placeholders replaced.
function Adjustments:PresencePlaceholders()
    local presence = Config.DiscordActivity.presence

    for placeholder, cb in pairs(placeHolders) do
        local success, result = pcall(cb)

        if not success then
            error(("Failed to execute presence placeholder: ^3%s^7"):format(
                      placeholder))
            error(result)
            return "Unknown"
        end

        presence = presence:gsub(("{%s}"):format(placeholder), result)
    end

    return presence
end

--- (Ré)applique les éléments STATIQUES de la rich presence : App ID, grande/petite
--- image (clés d'assets Discord), tooltips et boutons. Appelable à chaud quand le
--- panel EVE pousse une nouvelle config (cf. SetDiscordFromPanel).
function Adjustments:ApplyDiscordStatics()
    local d = Config.DiscordActivity
    if not d or not d.appId or d.appId == 0 then return end

    SetDiscordAppId(d.appId)

    if d.assetName and d.assetName ~= "" then
        SetDiscordRichPresenceAsset(d.assetName)
    end
    SetDiscordRichPresenceAssetText(d.assetText or "")

    if d.assetSmall and d.assetSmall ~= "" then
        SetDiscordRichPresenceAssetSmall(d.assetSmall)
        SetDiscordRichPresenceAssetSmallText(d.assetSmallText or "")
    end

    if type(d.buttons) == "table" then
        for i = 1, #d.buttons do
            local button = d.buttons[i]
            SetDiscordRichPresenceAction(i - 1, button.label, button.url)
        end
    end
end

--- Surcharge la config Discord avec le bloc `discord` du manifest panel EVE
--- (App ID, texte du statut, clés des grandes/petites images) puis réapplique à chaud.
---@param discord table|nil { appId, statusText|presence, largeImage, smallImage, ... }
function Adjustments:SetDiscordFromPanel(discord)
    if type(discord) ~= "table" then return end
    local d = Config.DiscordActivity
    if not d then return end

    local appId = tonumber(discord.appId)
    if appId and appId > 0 then d.appId = appId end

    local status = discord.statusText or discord.presence
    if type(status) == "string" and status ~= "" then d.presence = status end

    if type(discord.largeImage) == "string" and discord.largeImage ~= "" then d.assetName = discord.largeImage end
    if type(discord.largeImageText) == "string" and discord.largeImageText ~= "" then d.assetText = discord.largeImageText end
    if type(discord.smallImage) == "string" then d.assetSmall = discord.smallImage end
    if type(discord.smallImageText) == "string" and discord.smallImageText ~= "" then d.assetSmallText = discord.smallImageText end

    self:ApplyDiscordStatics()
end

--- Sets the Discord presence for the player.
function Adjustments:DiscordPresence()
    if Config.DiscordActivity.appId ~= 0 then
        CreateThread(function()
            self:ApplyDiscordStatics()

            while true do
                SetRichPresence(self:PresencePlaceholders())
                Wait(Config.DiscordActivity.refresh)
            end
        end)
    end
end

-- Le panel EVE pousse le branding (026_eve_branding.lua -> 'core:branding:apply').
-- On y applique le bloc `discord` du manifest à chaud (App ID, texte du statut,
-- clés des grandes/petites images), sans reconnexion.
RegisterNetEvent('core:branding:apply', function(payload)
    if type(payload) ~= 'table' then return end
    if payload.discord then
        Adjustments:SetDiscordFromPanel(payload.discord)
    end
    local name = payload.displayName or payload.name
    if type(name) == 'string' and name ~= '' and Config.DiscordActivity then
        Config.DiscordActivity.assetText = name
        Config.DiscordActivity.assetSmallText = name
        Adjustments:ApplyDiscordStatics()
    end
end)

--- Clears the player's wanted level and sets the maximum wanted level to 0.
function Adjustments:WantedLevel()
    SetMaxWantedLevel(0)
    CreateThread(function()
        while true do
            if GetPlayerWantedLevel(VFW.playerId) ~= 0 then
                ClearPlayerWantedLevel(VFW.playerId)
                SetPlayerWantedLevelNow(VFW.playerId, false)
            end
            SetMaxWantedLevel(0)
            Wait(500)
        end
    end)
end

--- Disables the radio in vehicles.
function Adjustments:DisableRadio()
    if Config.RemoveHudComponents[16] then
---@param vehicle any
---@param plate any
---@param seat any
---@param displayName string
---@param netId any
        AddEventHandler("vfw:enteredVehicle", function(vehicle, plate, seat, displayName, netId)
            SetVehRadioStation(vehicle, "OFF")
            SetUserRadioControlEnabled(false)
        end)
    end
end

--- Adds custom text entry for the authors.
function Adjustments:Authers()
    AddTextEntry('PM_PANE_CFX', '~HUD_COLOUR_TENNIS~' .. VFW.BrandName())
    SetWeaponsNoAutoswap(true)
    SetFlashLightKeepOnWhileMoving(true)

    local relationshipTypes = {
        "PLAYER", "CIVMALE", "CIVFEMALE", "COP", "SECURITY_GUARD", "PRIVATE_SECURITY", "FIREMAN",
        "GANG_1", "GANG_2", "GANG_9", "GANG_10", "AMBIENT_GANG_LOST", "AMBIENT_GANG_MEXICAN",
        "AMBIENT_GANG_FAMILY", "AMBIENT_GANG_BALLAS", "AMBIENT_GANG_MARABUNTE", "AMBIENT_GANG_CULT",
        "AMBIENT_GANG_SALVA", "AMBIENT_GANG_WEICHENG", "AMBIENT_GANG_HILLBILLY", "DEALER",
        "HATES_PLAYER", "HEN", "NO_RELATIONSHIP", "SPECIAL", "MISSION2", "MISSION3", "MISSION4",
        "MISSION5", "MISSION6", "MISSION7", "MISSION8", "ARMY", "GUARD_DOG", "AGGRESSIVE_INVESTIGATE",
        "MEDIC", "CAT"
    }
    local RELATIONSHIP_HATE = 1

    for _, v in pairs(relationshipTypes) do
        SetRelationshipBetweenGroups(RELATIONSHIP_HATE, joaat('PLAYER'), joaat(v))
        SetRelationshipBetweenGroups(RELATIONSHIP_HATE, joaat(v), joaat('PLAYER'))
    end

    -- États persistants: rafraîchis toutes les secondes (ou au changement de ped)
    CreateThread(function()
        local lastPed = nil
        while true do
            local ped = VFW.PlayerData.ped
            if ped ~= lastPed then
                lastPed = ped
                SetPedSuffersCriticalHits(ped, false)
                SetEveryoneIgnorePlayer(ped, true)
                SetPedConfigFlag(ped, 35, false)
            end
            Wait(1000)
        end
    end)

    -- Contrôles: doivent être désactivés chaque frame
    CreateThread(function()
        while true do
            DisableControlAction(0, 37, true)
            HudWeaponWheelIgnoreSelection()

            if IsAimCamActive() then
                DisableControlAction(1, 22, true)
            end

            if IsPedArmed(VFW.PlayerData.ped, 6) then
                DisableControlAction(1, 140, true)
                DisableControlAction(1, 141, true)
                DisableControlAction(1, 142, true)
            end

            Wait(0)
        end
    end)
end

-- Disable enter vehicle png
function Adjustments:NoCarJack()
    local excludedModels = {
        [joaat("bumpercar")] = true,
        [joaat("bmx")] = true,
        [joaat("cruiser")] = true,
        [joaat("fixter")] = true,
        [joaat("scorcher")] = true,
        [joaat("tribike")] = true,
        [joaat("tribike2")] = true,
        [joaat("tribike3")] = true
    }

    CreateThread(function()
        while true do
            Wait(500)

            if DoesEntityExist(GetVehiclePedIsTryingToEnter(VFW.PlayerData.ped)) then
                local veh = GetVehiclePedIsTryingToEnter(VFW.PlayerData.ped)
                local model = GetEntityModel(veh)
                local hasPlayer = false

                for i = -1, 3 do
                    local ped = GetPedInVehicleSeat(veh, i)

                    if ped and IsPedAPlayer(ped) then
                        hasPlayer = true
                        break
                    end
                end

                -- anti-vol des véhicules PNJ : jamais sur un véhicule géré par le serveur
                -- (possédé, activité, spawn staff, ou dont l'état de verrouillage est connu)
                local vehState = Entity(veh).state
                if not excludedModels[model]
                        and not vehState.VehicleProperties
                        and not vehState.OwnedVehicle
                        and not vehState.activityVehicle
                        and not vehState.staffVehicle
                        and vehState.doorsLocked == nil
                        and not hasPlayer
                        and not (VFW.PropertyGarageVehicles and VFW.PropertyGarageVehicles[veh]) then
                    if GetVehicleDoorLockStatus(veh) == 1 then
                        SetVehicleDoorsLocked(veh, 2)
                    end
                end

                local vPed = GetPedInVehicleSeat(veh, -1)

                if vPed and not IsPedAPlayer(vPed) then
                    SetPedCanBeDraggedOut(vPed, false)
                end
            end
        end
    end)
end

function Adjustments:RemoveCops()
    CreateThread(function()
        local config = {
            checkInterval = 1000,
            suppressionRadius = 400.0
        }

        SetCreateRandomCops(false)
        SetDispatchCopsForPlayer(PlayerId(), false)
        SetPoliceIgnorePlayer(PlayerId(), true)

        while true do
            local playerCoords = GetEntityCoords(PlayerPedId())

            ClearAreaOfCops(playerCoords.x, playerCoords.y, playerCoords.z, config.suppressionRadius, 0)

            Wait(config.checkInterval)
        end
    end)
end

function Adjustments:RemoveNPC()
    CreateThread(function()
        while true do
            Wait(0)
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        end
    end)
end

function Adjustments:RemoveStrafe()
    local pressAmount = 0
    local keys = { 30, 31 }

--- breakStrafe
---@param key any
---@param time any
    local function breakStrafe(key, time)
        CreateThread(function()
            local finishTime = GetGameTimer() + time

            while finishTime > GetGameTimer() do
                SetControlNormal(0, key, 1.0)
                Wait(0)
            end
        end)
    end

    CreateThread(function()
        while true do
            Wait(1000)

            if pressAmount > 4 then
                local key = IsControlJustPressed(0, 30) and 30 or 31
                breakStrafe(key, 250)
            end

            pressAmount = 0
        end
    end)

    CreateThread(function()
        while true do
            local time = 1000
            local playerPed = PlayerPedId()

            if IsPlayerFreeAiming(PlayerId()) and not IsPedInAnyVehicle(playerPed) then
                time = 0

                for i = 1, #keys do
                    if IsControlJustPressed(0, keys[i]) then
                        pressAmount = pressAmount + 1
                    end
                end
            end

            Wait(time)
        end
    end)
end

function Adjustments:RemoveRes()
    local wlRatio = {
        [177] = true, -- 16:9
        [233] = true, -- 21:9
        [237] = true, -- 21:9 - Widescreen
        [239] = true, -- 32:9
        [241] = true, -- 32:9 - Widescreen
        [243] = true, -- 32:9 - Ultra Widescreen
        [245] = true, -- 32:9 - Super Ultra Widescreen
    }

    CreateThread(function()
        while true do
            local aspectRatio = math.floor(GetAspectRatio() * 100)

            if not wlRatio[aspectRatio] then
                FreezeEntityPosition(VFW.PlayerData.ped, true)
                SendNUIMessage({
                    action = "nui:resolution:visible",
                    data = true
                })

                while not wlRatio[aspectRatio] do
                    aspectRatio = math.floor(GetAspectRatio() * 100)
                    Wait(100)
                end

                FreezeEntityPosition(VFW.PlayerData.ped, false)
                SendNUIMessage({
                    action = "nui:resolution:visible",
                    data = false
                })
            end

            Wait(1000)
        end
    end)
end

--- Hides the default GTA V health and armour bars on the minimap.
function Adjustments:HideHealthArmour()
    CreateThread(function()
        local minimap = RequestScaleformMovie("minimap")

        while not HasScaleformMovieLoaded(minimap) do
            Wait(0)
        end

        while true do
            BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            Wait(0)
        end
    end)
end

--- Loads all adjustments.
function Adjustments:Load()
    self:RemoveHudComponents()
    self:HideHealthArmour()
    self:DisableAimAssist()
    self:DisableNPCDrops()
    self:SeatShuffle()
    self:HealthRegeneration()
    self:AmmoAndVehicleRewards()
    self:EnablePvP()
    self:DispatchServices()
    self:DisableAmmunationGunshots()
    self:NPCScenarios()
    self:LicensePlates()
    self:DiscordPresence()
    self:WantedLevel()
    self:DisableRadio()
    self:Authers()
    self:NoCarJack()
    self:RemoveCops()
    self:RemoveNPC()
    self:RemoveStrafe()
end
