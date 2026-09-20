---@meta _
---@diagnostic disable: duplicate-doc-field

--- lightAnimation
---@param vehicle number|table Vehicle handle or object
local function lightAnimation(vehicle)

    for _ = 1, 2 do
        SetVehicleLights(vehicle, 2)
        Wait(150)
        SetVehicleLights(vehicle, 0)
        Wait(150)
    end
end

local animationDict = 'anim@mp_player_intmenu@key_fob@'
local modelHash = 'lr_prop_carkey_fob'
--- keyAnimation
local function keyAnimation()
    TaskPlayAnim(VFW.PlayerData.ped, animationDict, 'fob_click', 3.0, 3.0, -1, 48, 0.0, false, false, false)

    local playerCoords = GetEntityCoords(VFW.PlayerData.ped)
    local prop = VFW.OneSync.CreateObject(modelHash, playerCoords)
    AttachEntityToEntity(prop, VFW.PlayerData.ped, GetPedBoneIndex(VFW.PlayerData.ped, 57005), 0.14, 0.03, -0.01, 24.0,
        -152.0, 164.0, true, true, false, false, 1, true)

    Wait(1000)
    DeleteObject(prop)
    ClearPedTasks(VFW.PlayerData.ped)
end

RegisterNetEvent("vfw:vehicle:anim", function()
    local veh = VFW.Game.GetClosestVehicle()
    CreateThread(keyAnimation)
    lightAnimation(veh)
    PlayVehicleDoorCloseSound(veh, 1)
end)

local antiSpam = false

RegisterKeyMapping("+vehicleKey", "Ouvrir véhicule", "keyboard", "U")
RegisterCommand("+vehicleKey", function()
    if (Death and Death.isDead) or (VFW.PlayerData and VFW.PlayerData.dead) or LocalPlayer.state.isKnockedOut then return end
    if VFW.InsidePropertyGarage then return end
    if antiSpam then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Attendez 2 secondes !"
        })
    else
        antiSpam = true
        TriggerServerEvent("vfw:vehicle:open")
        SetTimeout(2000, function()
            antiSpam = false
        end)
    end
end)

RegisterClientCallback("vfw:vehicle:getManuFacture", function(model)
    return GetMakeNameFromVehicleModel(model)
end)

RegisterClientCallback("vfw:vehicle:getModelName", function(netId)
    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        local hash = GetEntityModel(vehicle)
        local displayName = GetDisplayNameFromVehicleModel(hash)
        if not displayName or displayName == "" or displayName == "CARNOTFOUND" or displayName == "NULL" then
            return nil
        end
        -- GetDisplayNameFromVehicleModel renvoie le <gameName> de vehicles.meta,
        -- pas toujours le nom de spawn. Pour les add-ons (Gabz "gbsultanrsx" -> "sultrsx"),
        -- les deux noms diffèrent ce qui casserait tout spawn futur depuis la BDD.
        -- On valide via joaat: si le hash ne correspond pas, on renvoie nil pour
        -- éviter de stocker un faux nom (le serveur affichera "modèle non reconnu").
        if GetHashKey(string.lower(displayName)) ~= hash then
            return nil
        end
        return displayName
    end
    return nil
end)

local passengerSeats = {1, 2, 3} -- Sièges passagers uniquement

-- Trouver le véhicule le plus proche
---Get ClosestVehicleToPlayer
---@param radius any
---@return table|nil Player object
function GetClosestVehicleToPlayer(radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = radius

    for _, vehicle in pairs(vehicles) do
        local vehCoords = GetEntityCoords(vehicle)
        local distance = #(playerCoords - vehCoords)

        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = vehicle
        end
    end

    return closestVehicle
end

-- Trouver un siège passager libre
---Get AvailablePassengerSeat
---@param vehicle number|table Vehicle handle or object
---@return any
function GetAvailablePassengerSeat(vehicle)
    for _, seatIndex in ipairs(passengerSeats) do
        if IsVehicleSeatFree(vehicle, seatIndex) then
            return seatIndex
        end
    end

    return nil
end



-- Associe la commande à la touche G (DÉSACTIVÉ - anciennement utilisé pour entrer en passager)
-- RegisterKeyMapping("enterpassenger", "Entrer en passager", "keyboard", "G")