---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Items = {}

---@param model any
RegisterNetEvent("vfw:requestModel", function(model)
    VFW.Streaming.RequestModel(model)
end)

---@param xPlayer number|table Player ID or object
---@param isNew any
---@param skin any
RegisterNetEvent("vfw:client:playerLoaded", function(xPlayer, isNew, skin)
    --VFW.PlayerData = xPlayer

    --if not Config.Multichar then
    --    VFW.SpawnPlayer(skin, VFW.PlayerData.coords, function()
    --        TriggerEvent("vfw:onPlayerLoaded")
    --        TriggerEvent("vfw:restoreLoadout")
    --        TriggerServerEvent("vfw:onPlayerLoaded")
    --        ShutdownLoadingScreen()
    --        ShutdownLoadingScreenNui()
    --    end)
    --
    --    if isNew then
    --        TriggerEvent("vfw:charCreator")
    --    end
    --end

    while not DoesEntityExist(VFW.PlayerData.ped) do
        Wait(20)
    end

    VFW.PlayerLoaded = true

    local timer = GetGameTimer()

    while not HaveAllStreamingRequestsCompleted(VFW.PlayerData.ped) and
            (GetGameTimer() - timer) < 2000 do
        Wait(0)
    end

    Adjustments:Load()

    ClearPedTasksImmediately(VFW.PlayerData.ped)

    if not Config.Multichar then
        Core.FreezePlayer(false)
    end

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    Actions:Init()
    Worlds.Zone.StartLoop()
    --StartServerSyncLoops()
    NetworkSetLocalPlayerSyncLookAt(true)
    SetTimeout(500, function()
        TriggerEvent("LoadHud")
        TriggerServerEvent("core:server:loadedLocation")
        ClearPedDecorations(VFW.PlayerData.ped)
        for _, tattoo in pairs(VFW.PlayerData.tattoos) do
            ApplyPedOverlay(VFW.PlayerData.ped, joaat(tattoo.Collection), joaat(tattoo.Hash))
        end

        local walk = GetResourceKvpString("walkstyle")
        if walk ~= nil then
            RequestWalking(walk)
            SetPedMovementClipset(VFW.PlayerData.ped, walk, 0.2)
            RemoveAnimSet(walk)
            -- Sync walk style with server for other players to copy
            TriggerServerEvent("vfw:animation:syncWalk", walk)
        end

        local expression = GetResourceKvpString("expression")
        if expression ~= nil then
            SetFacialIdleAnimOverride(VFW.PlayerData.ped, expression, 0)
        end

        -- Charger le style de visée sauvegardé
        local savedAimStyle = GetResourceKvpString("aim_style_animset")
        if savedAimStyle ~= nil then
            SetWeaponAnimationOverride(VFW.PlayerData.ped, savedAimStyle)
        end

        TriggerServerEvent("core:sync:onPlayerJoined")

        TriggerServerEvent("core:playerTimer:start")
        --local isWhitelist = (GetConvar('core_type', 'FA') == 'WL')
        --if not isWhitelist then
        --    TriggerServerEvent("core:antitroll:load")
        --end
        TriggerServerEvent("jail:load")
        TriggerEvent("vfw:playerReady", VFW.PlayerData)
        TriggerServerEvent("vfw:dev:playerLoaded", VFW.PlayerData.charNum)
        TriggerServerEvent("vfw:sellDrugs:Loaded")
        TriggerServerEvent("core:territories:findZone")

        if VFW.PlayerData.mugshot == nil or VFW.PlayerData.mugshot == "" or not VFW.PlayerData.mugshot then
            --TODO: Take the mugshot differently
            --ExecuteCommand("mugshot")
        end
    end)

end)

local isFirstSpawn = true
RegisterNetEvent("vfw:onPlayerLogout", function()
    VFW.PlayerLoaded = false
    isFirstSpawn = true
end)

---@param newMaxWeight number
RegisterNetEvent("vfw:setMaxWeight", function(newMaxWeight)
    VFW.SetPlayerData("maxWeight", newMaxWeight)
    if VFW.LoadInventories then
        VFW.LoadInventories()
    end
end)

---Event handler for PlayerSpawn
local function onPlayerSpawn()
    VFW.SetPlayerData("ped", PlayerPedId())
    VFW.SetPlayerData("dead", false)
end

--- playerSpawned
---@param coords vector3 Spawn coordinates
---@param heading number Spawn heading
AddEventHandler("playerSpawned", onPlayerSpawn)
AddEventHandler("vfw:onPlayerLoaded", function()
    onPlayerSpawn()

    if isFirstSpawn then
        isFirstSpawn = false

        if VFW.PlayerData.metadata.health and
                (VFW.PlayerData.metadata.health > 0 or Config.SaveDeathStatus) then
            SetEntityHealth(VFW.PlayerData.ped, VFW.PlayerData.metadata.health)
        end

        --if VFW.PlayerData.metadata.armor and VFW.PlayerData.metadata.armor > 0 then
        --    SetPedArmour(VFW.PlayerData.ped, VFW.PlayerData.metadata.armor)
        --end
    end
end)

AddEventHandler("vfw:onPlayerDeath", function()
    VFW.SetPlayerData("ped", PlayerPedId())
    VFW.SetPlayerData("dead", true)
end)

AddEventHandler("skinchanger:modelLoaded", function()
    while not VFW.PlayerLoaded do
        Wait(100)
    end

    TriggerEvent("vfw:restoreLoadout")
end)

AddEventHandler("vfw:restoreLoadout", function()
    VFW.SetPlayerData("ped", PlayerPedId())
end)

RegisterCommand("proper", function()
    local ped = VFW.PlayerData.ped
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
    ClearPedEnvDirt(ped)
    ClearPedWetness(ped)

    ExecuteCommand("e cleanhands")

    Wait(2500)
    ExecuteCommand("cancelemote")
    VFW.ShowNotification({
        type = 'VERT',
        content = "Personnage nettoyé"
    })
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("VehicleProperties", nil, function(bagName, _, value)
    if not value then
        return
    end

    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then
        console.debug(("^3Warning: Invalid netId from bagName: %s^7"):format(bagName))
        return
    end

    local maxTries = 30
    local tries = 0
    local vehicle

    while tries < maxTries do
        Wait(100)

        if not NetworkDoesEntityExistWithNetworkId(netId) then
            tries = tries + 1
            goto continue
        end

        vehicle = NetworkGetEntityFromNetworkId(netId)

        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
            if GetEntityType(vehicle) == 2 and NetworkGetEntityOwner(vehicle) == VFW.playerId then
                VFW.Game.SetVehicleProperties(vehicle, value)
                return
            end
        end

        tries = tries + 1
        ::continue::
    end

end)

-- Server-spawned owned vehicles keep `SetEntityOrphanMode(2)` server-side, but
-- each client's local GTA population manager will still despawn them when out
-- of streaming range unless they are flagged as mission entities locally.
--
-- The state-bag CHANGE handler below only fires when the value transitions
-- (typically once at spawn). It does NOT re-fire when the entity goes out of
-- scope and comes back into scope on this client: the local handle is fresh
-- but the state value is unchanged, so the mission flag is never re-applied
-- and the GTA engine can despawn the vehicle.
--
-- The periodic sweep further down catches that case by re-marking every
-- OwnedVehicle in scope at a low cadence.
local function pinOwnedVehicle(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if GetEntityType(vehicle) ~= 2 then return end
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("OwnedVehicle", nil, function(bagName, _, value)
    if not value then return end

    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then return end

    CreateThread(function()
        local tries = 0
        while tries < 30 do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                pinOwnedVehicle(NetworkGetEntityFromNetworkId(netId))
                return
            end
            Wait(100)
            tries = tries + 1
        end
    end)
end)

-- Verrouillage : l'état de référence est le state bag `doorsLocked` (posé par le serveur,
-- plugins/015_Features/server/vehicle_lock.lua). Chaque client l'applique localement, ce qui
-- reste cohérent quel que soit le propriétaire réseau du véhicule.
local function applyDoorLock(vehicle, locked)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if GetEntityType(vehicle) ~= 2 then return end
    local status = GetVehicleDoorLockStatus(vehicle)
    if locked then
        if status ~= 2 then SetVehicleDoorsLocked(vehicle, 2) end
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
    else
        if status ~= 1 then SetVehicleDoorsLocked(vehicle, 1) end
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
    end
end

-- Instant pin on stream-in : fires every time an entity is created locally,
-- including when it re-enters the player's scope after going away. Closes the
-- race window where a vehicle could be despawned by the GTA population manager
-- before the periodic sweep below caught it.
AddEventHandler("entityCreated", function(entity)
    if not entity or entity == 0 then return end
    if GetEntityType(entity) ~= 2 then return end
    if not NetworkGetEntityIsNetworked(entity) then return end
    local state = Entity(entity).state
    if state and state.OwnedVehicle then
        pinOwnedVehicle(entity)
    end
    if state and state.doorsLocked ~= nil then
        applyDoorLock(entity, state.doorsLocked == true)
    end
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("doorsLocked", nil, function(bagName, _, value)
    if value == nil then return end
    local netId = tonumber(bagName:match("entity:(%d+)"))
    if not netId then return end

    CreateThread(function()
        local tries = 0
        while tries < 30 do
            if NetworkDoesEntityExistWithNetworkId(netId) then
                applyDoorLock(NetworkGetEntityFromNetworkId(netId), value == true)
                return
            end
            Wait(100)
            tries = tries + 1
        end
    end)
end)

-- Periodic sweep : safety net in case entityCreated misses an entity.
CreateThread(function()
    while true do
        Wait(2000)
        local vehicles = GetGamePool("CVehicle")
        for i = 1, #vehicles do
            local veh = vehicles[i]
            if DoesEntityExist(veh) and NetworkGetEntityIsNetworked(veh) then
                local state = Entity(veh).state
                if state and state.OwnedVehicle then
                    pinOwnedVehicle(veh)
                end
                if state and state.doorsLocked ~= nil then
                    applyDoorLock(veh, state.doorsLocked == true)
                end
            end
        end
    end
end)

---@param account number
RegisterNetEvent("vfw:setAccountMoney", function(account)
    for i = 1, #VFW.PlayerData.accounts do
        if VFW.PlayerData.accounts[i].name == account.name then
            VFW.PlayerData.accounts[i] = account
            break
        end
    end

    VFW.SetPlayerData("accounts", VFW.PlayerData.accounts)
end)

---@param item any
---@param count number
---@param showNotification any
RegisterNetEvent("vfw:addInventoryItem", function(item, count, showNotification)
    for k, v in ipairs(VFW.PlayerData.inventory) do
        if v.name == item then
            VFW.PlayerData.inventory[k].count = count
            break
        end
    end
end)

---@param item any
---@param count number
---@param showNotification any
RegisterNetEvent("vfw:removeInventoryItem", function(item, count, showNotification)
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == item then
            VFW.PlayerData.inventory[i].count = count
            break
        end
    end
end)

RegisterNetEvent("vfw:addWeapon", function()
    error("event ^3'vfw:addWeapon'^1 Has Been Removed. Please use ^3xPlayer.addWeapon^1 Instead!")
end)

RegisterNetEvent("vfw:addWeaponComponent", function()
    error("event ^3'vfw:addWeaponComponent'^1 Has Been Removed. Please use ^3xPlayer.addWeaponComponent^1 Instead!")
end)

RegisterNetEvent("vfw:setWeaponAmmo", function()
    error("event ^3'vfw:setWeaponAmmo'^1 Has Been Removed. Please use ^3xPlayer.addWeaponAmmo^1 Instead!")
end)

---@param weapon any
---@param weaponTintIndex any
RegisterNetEvent("vfw:setWeaponTint", function(weapon, weaponTintIndex)
    SetPedWeaponTintIndex(VFW.PlayerData.ped, weapon, weaponTintIndex)
end)

RegisterNetEvent("vfw:removeWeapon", function()
    error("event ^3'vfw:removeWeapon'^1 Has Been Removed. Please use ^3xPlayer.removeWeapon^1 Instead!")
end)

---@param weapon any
---@param weaponComponent any
RegisterNetEvent("vfw:removeWeaponComponent", function(weapon, weaponComponent)
    local componentHash = VFW.GetWeaponComponent(weapon, weaponComponent).hash
    RemoveWeaponComponentFromPed(VFW.PlayerData.ped, joaat(weapon), componentHash)
end)

---@param weapon any
---@param ammo number
RegisterNetEvent("vfw:addWeaponClient", function(weapon, ammo)
    GiveWeaponToPed(VFW.PlayerData.ped, joaat(weapon), ammo or 0, false, false)
end)

---@param weapon any
RegisterNetEvent("vfw:removeWeaponClient", function(weapon)
    RemoveWeaponFromPed(VFW.PlayerData.ped, joaat(weapon))
end)

---@param weapon any
---@param ammo number
RegisterNetEvent("vfw:setWeaponAmmoClient", function(weapon, ammo)
    SetPedAmmo(VFW.PlayerData.ped, joaat(weapon), ammo or 0)
end)

---@param weapon any
---@param weaponComponent any
RegisterNetEvent("vfw:addWeaponComponentClient", function(weapon, weaponComponent)
    local componentHash = VFW.GetWeaponComponent(weapon, weaponComponent).hash
    GiveWeaponComponentToPed(VFW.PlayerData.ped, joaat(weapon), componentHash)
end)

---@param Faction any
RegisterNetEvent("vfw:setFaction", function(Faction)
    VFW.SetPlayerData("faction", Faction)
    if Faction ~= "" and Faction ~= "nocrew" then
        TriggerServerEvent("core:UpdateCrewCount", Faction, true)
    else
        TriggerServerEvent("core:UpdateCrewCount", Faction, false)
    end
end)

---@param group any
RegisterNetEvent("vfw:setGroup", function(group)
    VFW.SetPlayerData("group", group)
end)

---@param items any
RegisterNetEvent("vfw:loadItems", function(items)
    VFW.Items = items
end)

---@param nameItem string
---@param data table
RegisterNetEvent("vfw:createItem", function(nameItem, data)
    if VFW.Items[nameItem] then
        return
    end

    if not VFW.Items[nameItem] then
        VFW.Items[nameItem] = {}
    end

    VFW.Items[nameItem] = data
end)

---@param nameItem string
---@param data table
RegisterNetEvent("vfw:items:update", function(nameItem, data)
    VFW.Items[nameItem] = data
end)

-- function StartServerSyncLoops()
--     if Config.CustomInventory then return end

--     local currentWeapon = {
--         ---@type number
--         ---@diagnostic disable-next-line: assign-type-mismatch
--         hash = WEAPON_UNARMED,
--         ammo = 0
--     }

--     local function updateCurrentWeaponAmmo(weaponName)
--         local newAmmo = GetAmmoInPedWeapon(VFW.PlayerData.ped,
--                                            currentWeapon.hash)

--         if newAmmo ~= currentWeapon.ammo then
--             currentWeapon.ammo = newAmmo
--             TriggerServerEvent("vfw:updateWeaponAmmo", weaponName, newAmmo)
--         end
--     end

--     CreateThread(function()
--         while VFW.PlayerLoaded do
--             currentWeapon.hash = GetSelectedPedWeapon(VFW.PlayerData.ped)

--             if currentWeapon.hash ~= WEAPON_UNARMED then
--                 local weaponConfig = VFW.GetWeaponFromHash(currentWeapon.hash)

--                 if weaponConfig then
--                     currentWeapon.ammo =
--                         GetAmmoInPedWeapon(VFW.PlayerData.ped,
--                                            currentWeapon.hash)

--                     while GetSelectedPedWeapon(VFW.PlayerData.ped) ==
--                         currentWeapon.hash do
--                         updateCurrentWeaponAmmo(weaponConfig.name)
--                         Wait(1000)
--                     end

--                     updateCurrentWeaponAmmo(weaponConfig.name)
--                 end
--             end
--             Wait(250)
--         end
--     end)

--     CreateThread(function()
--         local PARACHUTE_OPENING<const> = 1
--         local PARACHUTE_OPEN<const> = 2

--         while VFW.PlayerLoaded do
--             local parachuteState = GetPedParachuteState(VFW.PlayerData.ped)

--             if parachuteState == PARACHUTE_OPENING or parachuteState ==
--                 PARACHUTE_OPEN then
--                 TriggerServerEvent("vfw:updateWeaponAmmo", "GADGET_PARACHUTE", 0)

--                 while GetPedParachuteState(VFW.PlayerData.ped) ~= -1 do
--                     Wait(1000)
--                 end
--             end
--             Wait(500)
--         end
--     end)
-- end

RegisterNetEvent("vfw:tpm", function()
    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
    local GetFirstBlipInfoId = GetFirstBlipInfoId
    local DoesBlipExist = DoesBlipExist
    local DoScreenFadeOut = DoScreenFadeOut
    local GetBlipInfoIdCoord = GetBlipInfoIdCoord
    local GetVehiclePedIsIn = GetVehiclePedIsIn
    local blipMarker = GetFirstBlipInfoId(8)

    local tpmTitle = (StaffMenu and StaffMenu.menuContext == 'animator') and VFW.AnimatorTitle() or nil

    if not DoesBlipExist(blipMarker) then
        VFW.ShowNotification({
            type = 'STAFF',
            title = tpmTitle,
            variant = 'ERROR',
            subtitle = 'Téléportations',
            message = "Aucun point n'est défini sur la carte."
        })
        return "marker"
    end

    -- Fade screen to hide how clients get teleported.
    DoScreenFadeOut(650)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ped, coords = VFW.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
    local vehicle = GetVehiclePedIsIn(ped, false)
    local oldCoords = GetEntityCoords(ped)

    -- Unpack coords instead of having to unpack them while iterating.
    -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
    local x, y, groundZ, Z_START = coords["x"], coords["y"], 850.0, 950.0
    local found = false
    FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

    for i = Z_START, 0, -25.0 do
        local z = i
        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()

        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end

            Wait(0)
        end

        NewLoadSceneStop()
        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then
                break
            end

            Wait(0)
        end

        -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ)
            break
        end

        Wait(0)
    end

    -- Remove black screen once the loop has ended.
    DoScreenFadeIn(650)
    FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)

    if not found then
        -- If we can't find the coords, set the coords to the old ones.
        -- We don't unpack them before since they aren't in a loop and only called once.
        SetPedCoordsKeepVehicle(ped, oldCoords["x"], oldCoords["y"],
                oldCoords["z"] - 1.0)
        VFW.ShowNotification({
            type = 'STAFF',
            title = tpmTitle,
            variant = 'WARNING',
            subtitle = 'Téléportations',
            message = "Téléporté au marqueur GPS (position approximative)."
        })
        return "ground"
    end

    -- If Z coord was found, set coords in found coords.
    SetPedCoordsKeepVehicle(ped, x, y, groundZ)
    VFW.ShowNotification({
        type = 'STAFF',
        title = tpmTitle,
        variant = 'SUCCESS',
        subtitle = 'Téléportations',
        message = "Téléporté au marqueur GPS."
    })

    -- Log avec from/to
    TriggerServerEvent("vfw:stafflogs:tpm", {
        x = math.floor(oldCoords["x"] * 10) / 10,
        y = math.floor(oldCoords["y"] * 10) / 10,
        z = math.floor(oldCoords["z"] * 10) / 10,
    }, {
        x = math.floor(x * 10) / 10,
        y = math.floor(y * 10) / 10,
        z = math.floor(groundZ * 10) / 10,
    })
end)

RegisterNetEvent("vfw:killPlayer", function(staffSource)
    if staffSource then
        VFW.DeathOverrideCause = "staff_kill"
        VFW.DeathOverrideStaffSource = staffSource
    end
    SetEntityHealth(VFW.PlayerData.ped, 0)
end)

RegisterNetEvent("vfw:repairPedVehicle", function()
    local ped = VFW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    SetVehicleEngineHealth(vehicle, 1000)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0)
    SetVehicleUndriveable(vehicle, false)
    Entity(vehicle).state:set("engineDestroyed", nil, true)
end)

RegisterClientCallback("vfw:GetVehicleType", function(model)
    return VFW.GetVehicleTypeClient(model)
end)

---@param key any
---@param val any
RegisterNetEvent('vfw:updatePlayerData', function(key, val)
    VFW.SetPlayerData(key, val)
end)

---@param resource number Player ID
AddEventHandler("onResourceStop", function(resource)
    if Core.Events[resource] then
        for i = 1, #Core.Events[resource] do
            RemoveEventHandler(Core.Events[resource][i])
        end
    end
end)

---@param data table
RegisterNetEvent('vfw:updatePlayerGlobalData', function(data)
    if not data then return end
    -- Préserver les champs critiques si le payload entrant ne les contient pas
    -- (évite qu'un trigger partiel wipe vip_tier ou permissions côté client)
    if VFW.PlayerGlobalData then
        if data.vip_tier == nil then
            data.vip_tier = VFW.PlayerGlobalData.vip_tier
        end
        if data.permissions == nil then
            data.permissions = VFW.PlayerGlobalData.permissions
        end
    end
    if VFW.HydrateNiveau6Permissions then
        VFW.HydrateNiveau6Permissions(data)
    end
    if VFW.IsSparseStaffPerms and VFW.IsSparseStaffPerms(data.permissions) then
        data.permissions = VFW.BuildFullPermissions()
    end
    VFW.PlayerGlobalData = data
end)

function VFW.SyncStaffAccess()
    if not TriggerServerCallback then return end
    local payload = TriggerServerCallback("vfw:staff:syncMyAccess")
    if VFW.ApplyStaffAccess then
        VFW.ApplyStaffAccess(payload)
    end
end

RegisterNetEvent('vfw:upgrade', function()
    local ped = VFW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    SetVehicleModKit(vehicle, 0)

    for i = 0, 49 do
        if i ~= 11 and i ~= 12 and i ~= 13 and i ~= 14 and i ~= 15 and i ~= 18 and i ~= 22 and i ~= 23 and i ~= 24 then
            local max = GetNumVehicleMods(vehicle, i) - 1
            if max > 0 then
                SetVehicleMod(vehicle, i, math.random(0, max), true)
            end
        end
    end

    for i = 11, 15 do
        local max = GetNumVehicleMods(vehicle, i) - 1
        SetVehicleMod(vehicle, i, max, true)
    end

    ToggleVehicleMod(vehicle, 18, true)
    ToggleVehicleMod(vehicle, 22, true)
end)

---@param color_1 any
RegisterNetEvent('vfw:setcarcolor', function(color_1)
    local ped = VFW.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    SetVehicleModKit(vehicle, 0)
    SetVehicleColours(vehicle, tonumber(color_1), tonumber(color_1))

    Wait(1000)

    TriggerServerEvent("vfw:staff:updateVeh", VFW.Game.GetVehicleProperties(vehicle))
end)

---@param netId any
---@param plate any
RegisterNetEvent('vfw:loadLightbarInCar', function(netId, plate)
    local vehicle = NetworkGetEntityFromNetworkId(netId)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        console.debug(("^1[ERROR] Invalid vehicle (netId: %s)^7"):format(netId))
        return
    end

    local success, result = pcall(function()
        return exports.vLightbar:loadLightbarInCar(vehicle, plate)
    end)

    if not success then
        console.debug(("^3[WARN] Lightbar load failed for vehicle %s: %s^7"):format(netId, result))
    end
end)

RegisterClientCallback("vfw:hasPedGotWeaponComponent", function(weapon, component)
    if HasPedGotWeaponComponent(VFW.PlayerData.ped, weapon, component) then
        return true
    end

    return false
end)