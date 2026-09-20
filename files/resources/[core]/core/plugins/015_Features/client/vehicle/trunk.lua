---@meta _
---@diagnostic disable: duplicate-doc-field

--region ------ Helper Functions

-- Cache for database vehicle storage config
local VehicleStorageConfigCache = {}      -- Cache par nom de modèle
local VehicleStorageHashCache = {}        -- Cache par hash de véhicule

-- Receive sync from server
RegisterNetEvent('vehicleStorage:syncConfig')
AddEventHandler('vehicleStorage:syncConfig', function(data, hashData)
    VehicleStorageConfigCache = data or {}
    VehicleStorageHashCache = hashData or {}
end)

--- Get vehicle config by hash (priority) or model name (fallback)
---@param veh any
---@return table|nil
local function GetVehicleStorageConfig(veh)
    local hash = GetEntityModel(veh)

    -- Priority 1: Lookup by hash
    if VehicleStorageHashCache[hash] then
        return VehicleStorageHashCache[hash]
    end

    -- Priority 2: Lookup by model name
    local modelName = string.lower(GetDisplayNameFromVehicleModel(hash))
    if VehicleStorageConfigCache[modelName] then
        return VehicleStorageConfigCache[modelName]
    end

    return nil
end

---Get Storage Weight
---@param veh any
---@param storageType string "trunk" or "glovebox"
---@return number
local function GetModelStorageWeight(veh, storageType)
    local dbConfig = GetVehicleStorageConfig(veh)

    if dbConfig then
        if storageType == "trunk" then
            return dbConfig.trunk_weight
        else
            return dbConfig.glovebox_weight
        end
    end

    -- Fallback: Hardcoded (vehicle_weights.lua)
    local model = GetEntityModel(veh)
    local config = VehicleModelWeights[model] or VehicleModelWeights.default
    return config[storageType] or 0
end

---Get Storage Slots
---@param veh any
---@param storageType string "trunk" or "glovebox"
---@return number
local function GetModelStorageSlots(veh, storageType)
    local dbConfig = GetVehicleStorageConfig(veh)

    if dbConfig then
        if storageType == "trunk" then
            return dbConfig.trunk_slots
        else
            return dbConfig.glovebox_slots
        end
    end

    -- Fallback: Hardcoded defaults
    if storageType == "trunk" then
        return 30
    else
        return 5
    end
end

---Check if player can enter trunk
---@param veh any
---@return boolean
local function CanEnterTrunk(veh)
    local dbConfig = GetVehicleStorageConfig(veh)

    if dbConfig then

        if dbConfig.can_enter_trunk == nil then
            return true
        end
        return dbConfig.can_enter_trunk
    end

    -- Par défaut, autorisé
    return true
end

---Get TrunkBone
---@param veh any
local function GetTrunkBone(veh)
    local bone = "platelight"
   if GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, bone)) == vector3(0, 0, 0) then
        if tostring(veh) == "826114" or tostring(veh) == "1377794" then
            -- stockade
            bone = "door_pside_r"
       elseif GetVehicleClass(veh) == 8 then
            bone = "swingarm"
       elseif GetVehicleClass(veh) == 20 then
            bone = "reversinglight_r"
       elseif GetVehicleClass(veh) == 14 then
            --boat
            bone = "engine"
       elseif GetVehicleClass(veh) == 16 then
            -- plane
            bone = "airbrake_l"
       elseif GetVehicleClass(veh) == 15 then
            -- plane
            bone = "engine"
       else
            bone = "boot"
       end
    end
    return bone
end

--- Vérifier si le joueur a les clés du véhicule
local function PlayerHasVehicleKeys(vehicle)
    if not VFW.PlayerData.inventory then
        return false
    end
    local plate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
    for i = 1, #VFW.PlayerData.inventory do
        local item = VFW.PlayerData.inventory[i]
        if item.name == "keys" and item.meta and item.meta.plate == plate then
            return true
        end
    end
    return false
end

--- Vérifier si un siège existe dans le véhicule
local function seatExists(vehicle, seat)
    if seat == -1 then
        return true
    end
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    return seat < maxPassengers
end

--- Vérifier si un siège est occupé
local function isSeatOccupied(vehicle, seat)
    local ped = GetPedInVehicleSeat(vehicle, seat)
    return ped and ped ~= 0 and DoesEntityExist(ped)
end

--- Obtenir l'ID du joueur dans un siège
local function getOccupantId(vehicle, seat)
    local ped = GetPedInVehicleSeat(vehicle, seat)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        local playerId = NetworkGetPlayerIndexFromPed(ped)
        if playerId and playerId ~= -1 then
            return "#" .. GetPlayerServerId(playerId)
        end
    end
    return nil
end

--- Vérifier si le véhicule a au moins un occupant
local function hasAnyOccupant(vehicle)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if isSeatOccupied(vehicle, seat) then
            return true
        end
    end
    return false
end

--- Obtenir le siège actuel du joueur
local function getCurrentSeat(veh)
    local ped = VFW.PlayerData.ped
    for i = -1, 3 do
        if GetPedInVehicleSeat(veh, i) == ped then
            return i
        end
    end
    return -2
end

--- OpenTrunk
---@param veh any
---@param bonePos vector3|table Position
---@return any
local function OpenTrunkAction(veh, bonePos)
    if VFW.StateInventory() then
        VFW.CloseInventory()
        return
    end

    if not VFW.Items then
        return
    end

    local ped = VFW.PlayerData.ped

    if not bonePos then
        bonePos = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, GetTrunkBone(veh)))
    end

    local animDict = 'mini@repair'
    local animName = 'fixing_a_player'
    VFW.Streaming.RequestAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 2.0, 2.0, 1500, 49, 0, false, false, false)
    Wait(500)
    SetVehicleDoorOpen(veh, 5, false, false)
    Wait(1000)
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)

    local OwnedVehicle = Entity(veh).state.OwnedVehicle
    VFW.OpenTrunk(OwnedVehicle, GetVehicleNumberPlateText(veh), VehToNet(veh))

    while VFW.StateInventory() do
        if #(GetEntityCoords(VFW.PlayerData.ped) - GetEntityCoords(veh)) > 5.0 then
            VFW.CloseInventory()
            break
        end

        if not IsNuiFocused() then
            VFW.Nui.Focus(true, true)
        end

        Wait(0)
    end

    VFW.Streaming.RequestAnimDict(animDict)
    TaskPlayAnim(ped, animDict, animName, 2.0, 2.0, 1200, 49, 0, false, false, false)
    Wait(400)
    SetVehicleDoorShut(veh, 5, false)
    Wait(800)
    ClearPedTasks(ped)
    RemoveAnimDict(animDict)
end

--endregion

--region ------ SUBMENUS (en premier)

-- 1. Changer de place (dans le véhicule)
local seatSubmenu = VFW.ContextAddSubmenu("vehicle", " Changer de place", function(veh)
    local ped = VFW.PlayerData.ped
    if not IsPedInVehicle(ped, veh, false) then
        return false
    end
    local CarSpeed = GetEntitySpeed(veh) * 3.6
    return CarSpeed <= 20.0
end, {}, nil)

VFW.ContextAddButton("vehicle", ":car: Conducteur", function(veh)
    return true
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == -1 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, -1) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, -1)
end, {}, seatSubmenu)

VFW.ContextAddButton("vehicle", ":user: Passager avant", function(veh)
    return GetVehicleMaxNumberOfPassengers(veh) >= 1
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == 0 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, 0) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, 0)
    SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
end, {}, seatSubmenu)

VFW.ContextAddButton("vehicle", ":user: Arrière gauche", function(veh)
    return GetVehicleMaxNumberOfPassengers(veh) >= 2
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == 1 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, 1) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, 1)
    SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
end, {}, seatSubmenu)

VFW.ContextAddButton("vehicle", ":user: Arrière droit", function(veh)
    return GetVehicleMaxNumberOfPassengers(veh) >= 3
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == 2 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, 2) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, 2)
    SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
end, {}, seatSubmenu)

local stretcherSeatModels = { [GetHashKey("hvsandbulance")] = true }

VFW.ContextAddButton("vehicle", ":box: Arrière gauche", function(veh)
    return stretcherSeatModels[GetEntityModel(veh)] == true
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == 3 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, 3) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, 3)
    SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
end, {}, seatSubmenu)

VFW.ContextAddButton("vehicle", ":box: Arrière droit", function(veh)
    return stretcherSeatModels[GetEntityModel(veh)] == true
end, function(veh)
    local currentSeat = getCurrentSeat(veh)
    if currentSeat == 4 then
        VFW.ShowNotification({ type = 'ORANGE', content = "Vous êtes déjà à cette place." })
        return
    end
    if not IsVehicleSeatFree(veh, 4) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette place est déjà occupée." })
        return
    end
    SetPedIntoVehicle(VFW.PlayerData.ped, veh, 4)
    SetPedConfigFlag(VFW.PlayerData.ped, 184, true)
end, {}, seatSubmenu)

--endregion

--region ------ BOUTONS PRINCIPAUX

-- Copier les IDs des occupants (disponible depuis l'extérieur)
VFW.ContextAddButton("vehicle", ":report: Copier les IDs des occupants", function(vehicle)
    return DoesEntityExist(vehicle) and hasAnyOccupant(vehicle)
end, function(vehicle)
    local occupantsList = {}
    local passengerCount = 0

    -- Parcourir tous les sièges (-1 = conducteur, 0+ = passagers)
    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if isSeatOccupied(vehicle, seat) then
            local occupantId = getOccupantId(vehicle, seat)
            if occupantId then
                local position
                if seat == -1 then
                    position = "Conducteur"
               else
                    passengerCount = passengerCount + 1
                    position = "Passager " .. passengerCount
                end

                table.insert(occupantsList, position .. ": " .. occupantId)
            end
        end
    end

    if #occupantsList > 0 then
        -- Concaténer avec des retours à la ligne pour le presse-papier
        local clipboardText = table.concat(occupantsList, "\n")

        -- Texte pour la notification (avec virgules)
        local notificationText = table.concat(occupantsList, ", ")

        -- Copier dans le presse-papier
        VFW.Clipboard(clipboardText)

        -- Afficher notification
        VFW.ShowNotification({
            type = "VERT",
            content = "IDs copiés: " .. notificationText
        })
    end
end)

-- Mettre de la musique (dans le véhicule)
VFW.ContextAddButton("vehicle", ":music: Mettre de la musique", function(veh)
    local ped = VFW.PlayerData.ped
    return IsPedInVehicle(ped, veh, false)
end, function(veh)
    VFW.CloseContextMenu()
    Wait(150)
    OpenVehicleMusicRadioUI(veh)
end)

-- Verrouiller/Déverrouiller (avec clés)
VFW.ContextAddButton("vehicle", ":lock: Verrouiller/Déverrouiller", function(vehicle)
    return DoesEntityExist(vehicle) and PlayerHasVehicleKeys(vehicle)
end, function(vehicle)
    local locked = GetVehicleDoorLockStatus(vehicle) > 1
    if locked then
        SetVehicleDoorsLocked(vehicle, 0)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        VFW.ShowNotification({ type = 'VERT', content = "Véhicule déverrouillé." })
    else
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleDoorsLockedForAllPlayers(vehicle, true)
        VFW.ShowNotification({ type = 'VERT', content = "Véhicule verrouillé." })
    end
end)

-- Ouvrir le coffre (extérieur, près du coffre)
VFW.ContextAddButton("vehicle", ":box: Ouvrir le coffre", function(veh)
    return not IsPedInAnyVehicle(VFW.PlayerData.ped, false)
            and (GetVehicleDoorLockStatus(veh) < 2) and Entity(veh).state.VehicleProperties
end, function(veh)

    OpenTrunkAction(veh)
end)


-- Se cacher dans le coffre (extérieur, près du coffre)
VFW.ContextAddButton("vehicle", ":box: Se cacher dans le coffre", function(veh)
    return DoesEntityExist(veh)
            and not IsPedInAnyVehicle(VFW.PlayerData.ped, false)
            and not VFW.IsInTrunk()
            and CanEnterTrunk(veh)
            and (#(GetEntityCoords(VFW.PlayerData.ped) - GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, GetTrunkBone(veh)))) < 2) and GetVehicleDoorLockStatus(veh) < 2
end, function(veh)
    local isLocked = GetVehicleDoorLockStatus(veh) > 1
    if isLocked then
        TriggerServerEvent('vfw:global:enterLockedTrunk', VehToNet(veh))
    end
    if VFW.EnterTrunk then
        VFW.EnterTrunk(veh)
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Fonction non disponible." })
    end
end)

-- Mettre quelqu'un dans le coffre (si on porte quelqu'un)
VFW.ContextAddButton("vehicle", ":box: Mettre dans le coffre", function(veh)
    if not VFW.IsCarrying() then
        return false
    end
    if not CanEnterTrunk(veh) then
        return false
    end
    local nearTrunk = (#(GetEntityCoords(VFW.PlayerData.ped) - GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, GetTrunkBone(veh)))) < 2)
    if not nearTrunk then
        return false
    end
    return (GetVehicleDoorLockStatus(veh) < 2)
end, function(veh)
    local targetSrc = VFW.GetCarryTarget()
    if targetSrc and targetSrc > 0 then
        VFW.StopCarrying()
        TriggerServerEvent('trunk:putPlayerInside', VehToNet(veh), targetSrc)
    end
end)

-- Sortir la personne du coffre (si quelqu'un est dedans)
VFW.ContextAddButton("vehicle", ":box: Sortir la personne du coffre", function(veh)
    if VFW.IsInTrunk() then
        return false
    end
    local nearTrunk = (#(GetEntityCoords(VFW.PlayerData.ped) - GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, GetTrunkBone(veh)))) < 2)
    if not nearTrunk then
        return false
    end
    return VFW.HasPlayerInTrunk and VFW.HasPlayerInTrunk(veh) or false
end, function(veh)
    TriggerServerEvent('trunk:forceExit', VehToNet(veh))
end)

-- Verrouiller/Déverrouiller le coffre (si quelqu'un est dedans)
VFW.ContextAddButton("vehicle", ":lock: Verrouiller/Déverrouiller le coffre", function(veh)
    if VFW.IsInTrunk() then
        return false
    end
    local nearTrunk = (#(GetEntityCoords(VFW.PlayerData.ped) - GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, GetTrunkBone(veh)))) < 2)
    if not nearTrunk then
        return false
    end
    return VFW.HasPlayerInTrunk and VFW.HasPlayerInTrunk(veh) or false
end, function(veh)
    TriggerServerEvent('trunk:toggleLock', VehToNet(veh))
end)

--endregion

--region ------ ACTIONS FACTION

local function hasJob2()
    return VFW.PlayerData
            and VFW.PlayerData.faction
            and VFW.PlayerData.faction.name
            and VFW.PlayerData.faction.name ~= ""
           and VFW.PlayerData.faction.name ~= "nofaction"
           and VFW.PlayerData.faction.name ~= "nocrew"
end

local function hasItem(itemName)
    if not VFW.PlayerData or not VFW.PlayerData.inventory then
        return false
    end
    for i = 1, #VFW.PlayerData.inventory do
        if VFW.PlayerData.inventory[i].name == itemName and VFW.PlayerData.inventory[i].count > 0 then
            return true
        end
    end
    return false
end

local function isVehicleLocked(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end
    local lockStatus = GetVehicleDoorLockStatus(vehicle)
    return lockStatus ~= 0 and lockStatus ~= 1
end

local function DoLockpickVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucun véhicule à proximité." })
        return
    end

    if not isVehicleLocked(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Le véhicule est déjà déverrouillé." })
        return
    end

    -- Vérification serveur et retrait de l'item
    local result = TriggerServerCallback("faction:menu:lockpick", NetworkGetNetworkIdFromEntity(vehicle))
    if not result or not result.success then
        VFW.ShowNotification({ type = 'ROUGE', content = result and result.message or "Erreur" })
        return
    end

    local playerPed = PlayerPedId()

    -- Se tourner vers le véhicule
    TaskTurnPedToFaceEntity(playerPed, vehicle, 1000)
    Wait(1000)

    -- Animation de soudure (comme pour la Fleeca)
    VFW.Streaming.RequestAnimDict('amb@world_human_welding@male@base')
    TaskPlayAnim(playerPed, 'amb@world_human_welding@male@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)

    -- Prop chalumeau
    local propHash = joaat("prop_weld_torch")
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(10)
    end

    local torch = VFW.OneSync.CreateObject(propHash, GetEntityCoords(playerPed))
    AttachEntityToEntity(torch, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)

    -- Progress bar
    local duration = VFW.Nui.ProgressBar("Crochetage en cours...", 15000)

    -- Nettoyage
    ClearPedTasks(playerPed)
    if DoesEntityExist(torch) then
        DeleteEntity(torch)
    end
    RemoveAnimDict('amb@world_human_welding@male@base')

    if duration then
        -- Succès - déverrouiller le véhicule
        NetworkRequestControlOfEntity(vehicle)
        local timeout = 0
        while not NetworkHasControlOfEntity(vehicle) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end

        SetVehicleDoorsLocked(vehicle, 1)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        VFW.ShowNotification({ type = 'VERT', content = "Véhicule crocheté." })
        TriggerServerEvent("faction:menu:lockpickSuccess", NetworkGetNetworkIdFromEntity(vehicle))
    else
        VFW.ShowNotification({ type = 'ROUGE', content = "Crochetage annulé." })
    end
end

-- Sous-menu Actions Faction sur véhicule
local subMenuFactionVehicle = VFW.ContextAddSubmenu("vehicle", ":users: Actions Faction", function(vehicle)
    return DoesEntityExist(vehicle) and hasJob2() and hasItem("chalumeau")
end, {}, nil)

-- Crocheter un véhicule (affiché seulement si le joueur possède un chalumeau)
VFW.ContextAddButton("vehicle", ":wrench: Crocheter", function(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end
    if not hasJob2() then
        return false
    end
    -- Ne pas afficher si le joueur n'a pas de chalumeau
    if not hasItem("chalumeau") then
        return false
    end
    return true
end, function(vehicle)
    -- Vérifier si le véhicule est verrouillé
    if not isVehicleLocked(vehicle) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Le véhicule est déjà déverrouillé." })
        return
    end

    DoLockpickVehicle(vehicle)
end, {}, subMenuFactionVehicle)

--endregion

--region ------ KEYBIND & FUNCTIONS

VFW.RegisterInput("opencartrunk", "Ouvrir coffre", "keyboard", "L", function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return
    end

    local veh = VFW.Game.GetClosestVehicle()
    if veh and veh > 0 then
        local bone = GetTrunkBone(veh)
        local boneIndex = GetEntityBoneIndexByName(veh, bone)
        local bonePos = GetWorldPositionOfEntityBone(veh, boneIndex)
        local playerPos = GetEntityCoords(VFW.PlayerData.ped)

        if #(playerPos - bonePos) > 2 then
            if #(playerPos - bonePos) < 4 then
                local line = true
                SetTimeout(1000, function()
                    line = false
                end)
                while line do
                    DrawLine(GetEntityCoords(VFW.PlayerData.ped), GetWorldPositionOfEntityBone(veh, boneIndex), 255, 255, 255, 170)
                    Wait(0)
                end
                VFW.ShowNotification({ type = 'ROUGE', content = "Vous êtes trop loin du coffre de ce véhicule." })
            end
            return
        end

        if (GetVehicleDoorLockStatus(veh) > 1) or (not Entity(veh).state.VehicleProperties) then
            VFW.ShowNotification({ type = 'ROUGE', content = "Le véhicule est verrouillé." })
            return
        end

        OpenTrunkAction(veh, bonePos)
    end
end)

function VFW.OpenTrunk(OwnedVehicle, plate, netId)
    local veh = NetToVeh(netId)
    local vehicleHash = GetEntityModel(veh)
    local vehicleModel = GetDisplayNameFromVehicleModel(vehicleHash)
    local chestId, inventory, weight, maxWeight, name = TriggerServerCallback("vfw:trunk:get", OwnedVehicle, plate, netId, vehicleModel, vehicleHash)
    local dynamicMaxSlots = GetModelStorageSlots(veh, "trunk")

    -- Use server maxWeight (includes VIP bonus), fallback to client config
    local finalMaxWeight = maxWeight or GetModelStorageWeight(veh, "trunk")

    VFW.OpenInventory({
        chestId = chestId,
        inventory = inventory,
        name = "Coffre",
        maxWeight = finalMaxWeight,
        weight = weight,
        search = false,
        type = "vehicle",
        maxSlots = dynamicMaxSlots
    })
end

function VFW.OpenTrunkStaff(plate, netId)
    local veh = NetToVeh(netId)
    if not veh or veh == 0 then return end

    local vehicleHash = GetEntityModel(veh)
    local vehicleModel = GetDisplayNameFromVehicleModel(vehicleHash)
    local chestId, inventory, weight, maxWeight = TriggerServerCallback("vfw:trunk:get-staff", plate, netId, vehicleModel, vehicleHash)

    if not chestId then
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Impossible d'ouvrir le coffre." })
        return
    end

    local dynamicMaxSlots = GetModelStorageSlots(veh, "trunk")
    local finalMaxWeight = maxWeight or GetModelStorageWeight(veh, "trunk")

    VFW.OpenInventory({
        chestId = chestId,
        inventory = inventory,
        name = "Coffre (lecture seule)",
        maxWeight = finalMaxWeight,
        weight = weight,
        search = false,
        type = "vehicle",
        maxSlots = dynamicMaxSlots,
        readOnly = true
    })
end

function VFW.OpenGloveBox(OwnedVehicle, plate, netId)
    local chestId, inventory, weight, maxWeight, name = TriggerServerCallback("vfw:glovebox:get", OwnedVehicle, plate, netId)
    local veh = NetToVeh(netId)
    local dynamicMaxWeight = GetModelStorageWeight(veh, "glovebox")
    local dynamicMaxSlots = GetModelStorageSlots(veh, "glovebox")

    VFW.OpenInventory({
        chestId = chestId,
        inventory = inventory,
        name = name,
        maxWeight = dynamicMaxWeight,
        weight = weight,
        search = false,
        type = "glovebox",
        maxSlots = dynamicMaxSlots
    })
end

--endregion
