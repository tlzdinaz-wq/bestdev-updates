---@meta _
---@diagnostic disable: duplicate-doc-field

-- Helper function to get closest vehicle at callback execution time (not at menu build time)
-- First checks if player is in a vehicle, then looks for nearby vehicles
local function getClosestVehicleNow()
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    if DoesEntityExist(playerVehicle) then
        return playerVehicle
    end
    local playerCoords = GetEntityCoords(playerPed)
    return GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 70)
end

-- Build Vehicle Extra Menu
function StaffMenu.BuildVehicleExtraMenu()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    -- Check if player is in a vehicle first, then look for nearby vehicles
    local closestVehicle = GetVehiclePedIsIn(playerPed, false)
    if not DoesEntityExist(closestVehicle) then
        closestVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 70)
    end
    
    -- Spawn vehicle by name
    StaffMenu.vehicleExtra.Button(":car: SPAWN VÉHICULE PAR NOM", "Faire apparaître un véhicule en saisissant son nom de modèle GTA", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["spawn_veh"], function()
        local modelName = VFW.Nui.KeyboardInput(true, "Nom du modèle du véhicule")
        
        if modelName and modelName ~= "" then
            local model = GetHashKey(modelName)
            
            if IsModelInCdimage(model) and IsModelAVehicle(model) then
                RequestModel(model)
                while not HasModelLoaded(model) do
                    Wait(10)
                end
                
                local vehicle = VFW.OneSync.CreateVehicleRaw(model, playerCoords, GetEntityHeading(playerPed))
                SetPedIntoVehicle(playerPed, vehicle, -1)
                SetModelAsNoLongerNeeded(model)
                
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                    message = "Véhicule spawné: " .. modelName
                })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                    message = "Ce modèle n'est pas valide: " .. modelName
                })
            end
        end
    end)
    
    -- Delete closest vehicle
    StaffMenu.vehicleExtra.Button(" SUPPRIMER LE VÉHICULE", "Supprimer le véhicule le plus proche ou celui dans lequel vous êtes", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["delete_veh"], function()
        local veh = getClosestVehicleNow()
        if DoesEntityExist(veh) then
            if NetworkGetEntityIsNetworked(veh) then
                local netId = NetworkGetNetworkIdFromEntity(veh)
                if netId and netId ~= 0 then
                    TriggerServerEvent("vfw:staff:deleteVehicle", netId)
                else
                    DeleteEntity(veh)
                end
            else
                DeleteEntity(veh)
            end

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                message = "Véhicule supprimé"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche"
          })
        end
    end)
    
    -- Repair vehicle
    StaffMenu.vehicleExtra.Button(":wrench: RÉPARER LE VÉHICULE", "Réparer la carrosserie, le moteur et le réservoir du véhicule proche", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["repair_veh"], function()
        local veh = getClosestVehicleNow()
        if DoesEntityExist(veh) then
            SetVehicleFixed(veh)
            SetVehicleDeformationFixed(veh)
            SetVehicleEngineHealth(veh, 1000.0)
            SetVehicleBodyHealth(veh, 1000.0)
            SetVehiclePetrolTankHealth(veh, 1000.0)

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                message = "Véhicule réparé"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche"
          })
        end
    end)

    StaffMenu.vehicleExtra.Button(" S'ATTRIBUER LE VÉHICULE", "Enregistrer le véhicule proche à votre nom dans la base de données", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["alt_assign_vehicle"], function()
        local veh = getClosestVehicleNow()
        if not DoesEntityExist(veh) then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche ou vous n'êtes pas dans un véhicule"
          })
            return false
        end
        local plate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
        local modelHash = GetEntityModel(veh)
        local model = string.lower(GetDisplayNameFromVehicleModel(modelHash))
        -- GetDisplayNameFromVehicleModel renvoie le <gameName> de vehicles.meta,
        -- pas le nom de modèle utilisé pour spawn. Pour les add-ons (Gabz, etc.)
        -- les deux noms diffèrent ("gbsultanrsx" -> "sultrsx"), ce qui empêche
        -- tout futur spawn depuis la BDD. On valide via joaat et on prompt si KO.
        if GetHashKey(model) ~= modelHash then
            local prompt = VFW.Nui.KeyboardInput(true, "Nom de modele introuvable, tape le nom spawn (ex: gbsultanrsx)")
            if not prompt or prompt == "" or prompt == "KBD_CANCEL" then
                return false
            end
            local cleaned = string.lower(prompt)
            if GetHashKey(cleaned) ~= modelHash then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Vehicules',
                    message = "Ce nom de modele ne correspond pas au vehicule."
              })
                return false
            end
            model = cleaned
        end
        local vehicleName = GetMakeNameFromVehicleModel(modelHash) .. " " .. GetLabelText(GetDisplayNameFromVehicleModel(modelHash))
        if not NetworkGetEntityIsNetworked(veh) then return false end
        local netId = NetworkGetNetworkIdFromEntity(veh)
        local props = VFW.Game.GetVehicleProperties(veh)
        local result = TriggerServerCallback("vfw:staff:assignSelfVehicle", plate, model, netId, props)
        if not result or not result.success then
            return false
        end
        StaffMenu.data.vehicleExtraSelected = {
            plate = result.plate,
            name = vehicleName,
            stored = result.stored,
            model = result.model
        }
    end, StaffMenu.vehicleExtraActions)

    StaffMenu.vehicleExtra.Separator(":car: GESTION VÉHICULE")

    StaffMenu.vehicleExtra.Button(":id: CHANGER LA PLAQUE", "Modifier la plaque d'immatriculation du véhicule (8 caractères max)", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["change_plate"], function()
        local veh = getClosestVehicleNow()
        if DoesEntityExist(veh) then
            local newPlate = VFW.Nui.KeyboardInput(true, "Nouvelle plaque (8 caractères max)")

            if not newPlate or newPlate == "" or newPlate == "KBD_CANCEL" then
                return
            end

            if #newPlate > 8 then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                    message = "Cette plaque n'est pas valide (8 caractères max)"
              })
                return
            end

            local oldPlate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
            local success = TriggerServerCallback("vfw:vehicle:changePlate", oldPlate, newPlate)

            if success then
                SetVehicleNumberPlateText(veh, newPlate)
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                    message = "Plaque changée: " .. newPlate
                })
            else
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                    message = "Cette plaque est déjà utilisée ou le véhicule n'existe pas en base"
              })
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche"
          })
        end
    end)
    
    -- Flip vehicle
    StaffMenu.vehicleExtra.Button(":refresh: RETOURNER LE VÉHICULE", "Remettre le véhicule proche dans le bon sens s'il est retourné", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["flip_veh"], function()
        local veh = getClosestVehicleNow()
        if DoesEntityExist(veh) then
            SetVehicleOnGroundProperly(veh)
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                message = "Véhicule retourné"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche"
          })
        end
    end)
    
    -- Upgrade vehicle
    StaffMenu.vehicleExtra.Button(":arrow: AMÉLIORER LE VÉHICULE", "Passer toutes les performances du véhicule au maximum en un clic", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["upgrade_veh"], function()
        local veh = getClosestVehicleNow()
        if DoesEntityExist(veh) then
            SetVehicleModKit(veh, 0)

            -- Max out performance mods
            SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false) -- Engine
            SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false) -- Brakes
            SetVehicleMod(veh, 13, GetNumVehicleMods(veh, 13) - 1, false) -- Transmission
            SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false) -- Suspension
            SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false) -- Armor
            ToggleVehicleMod(veh, 18, true) -- Turbo

            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Extras Véhicules',
                message = "Véhicule amélioré au maximum"
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Extras Véhicules',
                message = "Aucun véhicule proche"
          })
        end
    end)

    StaffMenu.vehicleExtra.Separator("CUSTOMISATION COMPLETE")

    StaffMenu.vehicleExtra.Button("OUVRIR MENU CUSTOM COMPLET", "Accéder au menu de customisation avancée : couleurs, roues, éclairage et plus", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["staff_custom"], function()
            StaffMenu.OpenVehicleCustomMenu(StaffMenu.vehicleExtra)
        end)
end

function StaffMenu.BuildVehicleExtraActionsMenu()
    StaffMenu.vehicleExtraActions.ClearItems()
    local veh = StaffMenu.data.vehicleExtraSelected
    if not veh then
        StaffMenu.vehicleExtraActions.Separator("Aucun véhicule sélectionné")
        return
    end

    local isSpawned, vehPos = TriggerServerCallback('vfw:staff:isVehicleSpawned', veh.plate)

    local status
    if isSpawned then
        status = "sorti"
  elseif veh.stored == "fourriere" then
        status = "fourriere"
  else
        status = "garage"
  end
    veh.stored = status

    local statusLabel = StaffMenu.getStorageLabel(status)
    local isInGarage = (status == "garage")
    local isInPound = (status == "fourriere")

    StaffMenu.vehicleExtraActions.Title(veh.name, veh.plate .. " | " .. statusLabel)

    StaffMenu.vehicleExtraActions.Separator(":pin: Stockage")

    StaffMenu.vehicleExtraActions.Button(":home: Mettre au garage", nil, nil, "chevron", isInGarage or not VFW.PlayerGlobalData.permissions["staff_vehicle_state"], function()
        local props = StaffMenu.getSpawnedVehicleProps(veh.plate)
        TriggerServerEvent("vfw:staff:setVehicleState", veh.plate, "garage", props)
        veh.stored = "garage"
      StaffMenu.refreshVehsList()
        StaffMenu.vehicleExtraActions.refresh()
    end)

    StaffMenu.vehicleExtraActions.Button(":unlock: Sortir de la fourrière", nil, nil, "chevron", not isInPound or not VFW.PlayerGlobalData.permissions["staff_vehicle_state"], function()
        TriggerServerEvent("vfw:staff:setVehicleState", veh.plate, "garage")
        veh.stored = "garage"
      StaffMenu.refreshVehsList()
        StaffMenu.vehicleExtraActions.refresh()
    end)
    StaffMenu.vehicleExtraActions.Button(":siren: Mettre en fourrière", nil, nil, "chevron", isInPound or not VFW.PlayerGlobalData.permissions["staff_vehicle_state"], function()
        TriggerServerEvent("vfw:staff:setVehicleState", veh.plate, "fourriere")
        veh.stored = "fourriere"
      StaffMenu.refreshVehsList()
        StaffMenu.vehicleExtraActions.refresh()
    end)

    StaffMenu.vehicleExtraActions.Button(":car: Spawn le véhicule", nil, nil, "chevron", isSpawned or not VFW.PlayerGlobalData.permissions["staff_vehicle_spawn"], function()
        TriggerServerEvent("vfw:staff:spawnVehicleForPlayer", GetPlayerServerId(PlayerId()), veh.plate)
        veh.stored = "sorti"
      Wait(500)
        StaffMenu.refreshVehsList()
        StaffMenu.vehicleExtraActions.refresh()
    end)

    StaffMenu.vehicleExtraActions.Separator(":wrench: Actions")

    StaffMenu.vehicleExtraActions.Button("TP au véhicule", nil, nil, "chevron", not isSpawned or not VFW.PlayerGlobalData.permissions["staff_vehicle_tp"], function()
        TriggerServerEvent("vfw:staff:tpToVehicle", veh.plate)
    end)

    StaffMenu.vehicleExtraActions.Button("Supprimer le véhicule", nil, nil, "chevron", not isSpawned or not VFW.PlayerGlobalData.permissions["staff_vehicle_delete_spawned"], function()
        TriggerServerEvent("vfw:staff:deleteSpawnedVehicle", veh.plate)
        StaffMenu.refreshVehsList()
        StaffMenu.vehicleExtraActions.refresh()
    end)

    StaffMenu.vehicleExtraActions.Separator(":key: Gestion des clés")

    StaffMenu.vehicleExtraActions.Button("Clés temporaires (reboot)", "Disparaissent au redémarrage", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["vehicle_keys_temp"], function()
        local vehicles = GetGamePool('CVehicle')
        local targetVehicle = nil
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehiclePlate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
                if vehiclePlate == veh.plate then
                    targetVehicle = vehicle
                    break
                end
            end
        end

        if targetVehicle then
            if not NetworkGetEntityIsNetworked(targetVehicle) then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                    message = "Le véhicule n'est pas synchronisé sur le réseau"
              })
            else
                local netId = NetworkGetNetworkIdFromEntity(targetVehicle)
                local result = TriggerServerCallback("vfw:action:run", {
                    action = "vehicle:getKeysTemp",
                    ent = { netId = netId, entType = 2 },
                    permission = "vehicle_keys_temp"
              })

                if result.ok then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
                        message = "Vous avez pris les clés temporaires du véhicule"
                  })
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                        message = "Impossible de récupérer les clés"
                  })
                end
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule doit être spawné pour prendre les clés"
          })
        end
    end)

    StaffMenu.vehicleExtraActions.Button("Clés permanentes", "Persistent après redémarrage", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["vehicle_keys_permanent"], function()
        local vehicles = GetGamePool('CVehicle')
        local targetVehicle = nil
        for _, vehicle in ipairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehiclePlate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
                if vehiclePlate == veh.plate then
                    targetVehicle = vehicle
                    break
                end
            end
        end

        if targetVehicle then
            if not NetworkGetEntityIsNetworked(targetVehicle) then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                    message = "Le véhicule n'est pas synchronisé sur le réseau"
              })
            else
                local netId = NetworkGetNetworkIdFromEntity(targetVehicle)
                local result = TriggerServerCallback("vfw:action:run", {
                    action = "vehicle:getKeys",
                    ent = { netId = netId, entType = 2 },
                    permission = "vehicle_keys_permanent"
              })

                if result.ok then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
                        message = "Vous avez pris les clés permanentes du véhicule"
                  })
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                        message = "Impossible de récupérer les clés"
                  })
                end
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule doit être spawné pour prendre les clés"
          })
        end
    end)

    StaffMenu.vehicleExtraActions.Button("Transférer le véhicule", "Changer le propriétaire", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["alt_give_vehicle"], function()
        VFW.Nui.Focus(true)
        local targetId = VFW.Nui.KeyboardInput(true, "ID du nouveau propriétaire", "", 10)

        if targetId == nil or targetId == "" or targetId == "KBD_CANCEL" then
            return
        end

        if not tonumber(targetId) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules', message = "Cet identifiant n'est pas valide" })
            return
        end

        TriggerServerEvent("vfw:staff:transferVehicle", veh.plate, tonumber(targetId))
    end)
end

RegisterNetEvent("vfw:staff:refreshVehicleExtraActionsMenu", function(newState)
    if StaffMenu.vehicleExtraActions and StaffMenu.data.vehicleExtraSelected then
        if newState then
            StaffMenu.data.vehicleExtraSelected.stored = newState
        end
        if StaffMenu.vehicleExtraActions.opened then
            StaffMenu.vehicleExtraActions.refresh(true)
        end
    end
end)

-- Draw marker on closest vehicle
CreateThread(function()
    while true do
        Wait(0)
        
        if StaffMenu.vehicleExtra and StaffMenu.vehicleExtra.visible then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestVehicle = GetClosestVehicle(playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 70)
            
            if DoesEntityExist(closestVehicle) then
                local vehCoords = GetEntityCoords(closestVehicle)
                DrawMarker(
                    21, 
                    vehCoords.x, 
                    vehCoords.y, 
                    vehCoords.z + 1.3, 
                    0.0, 0.0, 0.0, 
                    0.0, 0.0, 0.0, 
                    0.3, 0.3, 0.3, 
                    255, 0, 0, 255, 
                    true, true, 2, true, nil, nil, false
                )
            end
        else
            Wait(500)
        end
    end
end)