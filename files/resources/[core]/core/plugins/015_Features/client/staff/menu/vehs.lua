---@meta _
---@diagnostic disable: duplicate-doc-field

-- Store selected vehicle data for the actions menu
StaffMenu.data.selectedVehicle = nil
StaffMenu.data.selectedVehicleType = nil
StaffMenu.data.skipVehicleServerCheck = false
-- Lookup mode (depuis menu Outils Staff) : limite les actions au stockage uniquement
StaffMenu.data.vehsLookupMode = false

function StaffMenu.getSpawnedVehicleProps(plate)
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))
            if vehiclePlate == plate then
                return VFW.Game.GetVehicleProperties(vehicle)
            end
        end
    end
    return nil
end

--- Helper function to get storage location label
---@param stored string|number|boolean|nil
---@return string
function StaffMenu.getStorageLabel(stored)
    if stored == "sorti" then
        return "Sorti"
  elseif stored == "fourriere" then
        return "Fourrière"
  elseif stored == "garage" then
        return "Garage"
  elseif stored == "propriete" then
        return "Propriété"
  elseif stored == true or stored == 0 then
        return "Sorti"
  elseif stored == false or stored == 1 then
        return "Garage"
  else
        return "Inconnu"
  end
end

--- .BuildVehsMenu
function StaffMenu.BuildVehsMenu()
    StaffMenu.vehs.ClearItems()
    local totalVehs = #(StaffMenu.data.vehsList.owned or {}) + #(StaffMenu.data.vehsList.job or {}) + #(StaffMenu.data.vehsList.faction or {})
    StaffMenu.vehs.Title("Véhicules", "de " .. StaffMenu.data.playerInfo.name, totalVehs)

    StaffMenu.vehs.Button("Personnel", "Voir les véhicules personnels appartenant au joueur", nil, "chevron", #(StaffMenu.data.vehsList.owned or {}) == 0, function()
        StaffMenu.BuildVehsOwnedMenu()
    end, StaffMenu.vehs_owned)

    local info = StaffMenu.data.playerInfo
    if info and info.jobName and info.jobName ~= "unemployed" then
        StaffMenu.vehs.Button("Job", "Voir les véhicules du job actuellement assigné au joueur", nil, "chevron", #(StaffMenu.data.vehsList.job or {}) == 0, function()
            StaffMenu.BuildVehsJobMenu()
        end, StaffMenu.vehs_job)
    end

    if info and info.factionName then
        StaffMenu.vehs.Button("Faction", "Voir les véhicules de la faction actuellement assignée au joueur", nil, "chevron", #(StaffMenu.data.vehsList.faction or {}) == 0, function()
            StaffMenu.BuildVehsFactionMenu()
        end, StaffMenu.vehs_faction)
    end
end

--- .BuildVehsOwnedMenu
function StaffMenu.BuildVehsOwnedMenu()
    StaffMenu.vehs_owned.ClearItems()
    if StaffMenu.data.vehsList and #(StaffMenu.data.vehsList.owned or {}) > 0 then
        for i = 1, #StaffMenu.data.vehsList.owned do
            local veh = StaffMenu.data.vehsList.owned[i]
            local vehicleName = Garage.GetVehicleLabel(veh.name)
            local storageLabel = StaffMenu.getStorageLabel(veh.stored)

            StaffMenu.vehs_owned.Button(vehicleName, veh.plate, storageLabel, "chevron", false, function()
                StaffMenu.data.selectedVehicle = {
                    plate = veh.plate,
                    name = vehicleName,
                    stored = veh.stored,
                    model = veh.name
                }
                StaffMenu.data.selectedVehicleType = "owned"
              -- Appel manuel pour garantir la construction du menu Actions
                StaffMenu.BuildVehicleActionsMenu()
            end, StaffMenu.vehicleActions)
        end
    else
        StaffMenu.vehs_owned.Separator("Aucun véhicule personnel")
    end
end

--- .BuildVehsJobMenu
function StaffMenu.BuildVehsJobMenu()
    StaffMenu.vehs_job.ClearItems()
    if StaffMenu.data.vehsList and #(StaffMenu.data.vehsList.job or {}) > 0 then
        for i = 1, #StaffMenu.data.vehsList.job do
            local veh = StaffMenu.data.vehsList.job[i]
            local vehicleName = Garage.GetVehicleLabel(veh.name)
            local storageLabel = StaffMenu.getStorageLabel(veh.stored)

            StaffMenu.vehs_job.Button(vehicleName, veh.plate, storageLabel, "chevron", false, function()
                StaffMenu.data.selectedVehicle = {
                    plate = veh.plate,
                    name = vehicleName,
                    stored = veh.stored,
                    model = veh.name
                }
                StaffMenu.data.selectedVehicleType = "job"
              -- Appel manuel pour garantir la construction du menu Actions
                StaffMenu.BuildVehicleActionsMenu()
            end, StaffMenu.vehicleActions)
        end
    else
        StaffMenu.vehs_job.Separator("Aucun véhicule dans le Job")
    end
end

--- .BuildVehsFactionMenu
function StaffMenu.BuildVehsFactionMenu()
    StaffMenu.vehs_faction.ClearItems()
    if StaffMenu.data.vehsList and #(StaffMenu.data.vehsList.faction or {}) > 0 then
        for i = 1, #StaffMenu.data.vehsList.faction do
            local veh = StaffMenu.data.vehsList.faction[i]
            local vehicleName = Garage.GetVehicleLabel(veh.name)
            local storageLabel = StaffMenu.getStorageLabel(veh.stored)

            StaffMenu.vehs_faction.Button(vehicleName, veh.plate, storageLabel, "chevron", false, function()
                StaffMenu.data.selectedVehicle = {
                    plate = veh.plate,
                    name = vehicleName,
                    stored = veh.stored,
                    model = veh.name
                }
                StaffMenu.data.selectedVehicleType = "faction"
              -- Appel manuel pour garantir la construction du menu Actions
                StaffMenu.BuildVehicleActionsMenu()
            end, StaffMenu.vehicleActions)
        end
    else
        StaffMenu.vehs_faction.Separator("Aucun véhicule dans la Faction")
    end
end

--- Helper function to refresh the correct vehicle list after an action
local function refreshVehicleList()
    local vehType = StaffMenu.data.selectedVehicleType
    if vehType == "owned" then
        StaffMenu.data.vehsList = TriggerServerCallback("core:server:GetTypeVehicle", StaffMenu.data.selectedPlayer, "owned") or {}
    elseif vehType == "job" then
        StaffMenu.data.vehsList = TriggerServerCallback("core:server:GetTypeVehicle", StaffMenu.data.selectedPlayer, "job") or {}
    elseif vehType == "faction" then
        StaffMenu.data.vehsList = TriggerServerCallback("core:server:GetTypeVehicle", StaffMenu.data.selectedPlayer, "faction") or {}
    end
end

--- Sync selectedVehicle.stored back into vehsList source and rebuild the list menu
local function syncVehicleListStatus()
    local selected = StaffMenu.data.selectedVehicle
    if not selected then return end

    local vehType = StaffMenu.data.selectedVehicleType
    local list = vehType and StaffMenu.data.vehsList and StaffMenu.data.vehsList[vehType]
    if list then
        for i = 1, #list do
            if list[i].plate == selected.plate then
                list[i].stored = selected.stored
                break
            end
        end
    end

    -- Rebuild the parent vehicle list menu
    if vehType == "owned" then
        StaffMenu.BuildVehsOwnedMenu()
    elseif vehType == "job" then
        StaffMenu.BuildVehsJobMenu()
    elseif vehType == "faction" then
        StaffMenu.BuildVehsFactionMenu()
    end
end

function StaffMenu.refreshVehsList()
    if not StaffMenu.data.selectedPlayer then return end
    local newData = TriggerServerCallback("core:server:GetAllVehicle", StaffMenu.data.selectedPlayer)
    if newData then
        StaffMenu.data.vehsList = newData
    end
end

--- .BuildVehicleActionsMenu
function StaffMenu.BuildVehicleActionsMenu()
    StaffMenu.vehicleActions.ClearItems()
    local veh = StaffMenu.data.selectedVehicle
    if not veh then
        StaffMenu.vehicleActions.Separator("Aucun véhicule sélectionné")
        return
    end

    local isPersonal = (StaffMenu.data.selectedVehicleType == "owned")
    local status

    if StaffMenu.data.skipVehicleServerCheck then
        StaffMenu.data.skipVehicleServerCheck = false
        status = veh.stored or "garage"
  else
        local serverSpawned = TriggerServerCallback('vfw:staff:isVehicleSpawned', veh.plate)

        if serverSpawned then
            status = "sorti"
      elseif isPersonal and veh.stored == "fourriere" then
            status = "fourriere"
      else
            status = "garage"
      end
        veh.stored = status
    end

    local statusLabel = StaffMenu.getStorageLabel(status)
    local isInGarage = (status == "garage")
    local isInPound = (status == "fourriere")
    local isSpawned = (status == "sorti")

    -- Title with vehicle info and status
    StaffMenu.vehicleActions.Title(veh.name, veh.plate .. " | " .. statusLabel)

    StaffMenu.vehicleActions.Separator(":pin: Stockage")

    local lookupMode = StaffMenu.data.vehsLookupMode
    local canState = lookupMode or VFW.PlayerGlobalData.permissions["staff_vehicle_state"]
    local canSpawn = lookupMode or VFW.PlayerGlobalData.permissions["staff_vehicle_spawn"]

    local setStateEvent = lookupMode and "vfw:staff:lookupSetVehicleState" or "vfw:staff:setVehicleState"

  -- Mettre au garage - Disabled if already in garage
    StaffMenu.vehicleActions.Button(":home: Mettre au garage", "Ranger ce véhicule dans le garage du joueur", nil, "chevron", isInGarage or not canState, function()
        local props = StaffMenu.getSpawnedVehicleProps(veh.plate)
        TriggerServerEvent(setStateEvent, veh.plate, "garage", props)
        veh.stored = "garage"
      syncVehicleListStatus()
        StaffMenu.data.skipVehicleServerCheck = true
        StaffMenu.vehicleActions.refresh(true)
    end)

    -- Fourrière (uniquement pour véhicules personnels)
    StaffMenu.vehicleActions.Button(":unlock: Sortir de la fourrière", "Libérer le véhicule de la fourrière et le remettre au garage", nil, "chevron", not isPersonal or not isInPound or not canState, function()
        TriggerServerEvent(setStateEvent, veh.plate, "garage")
        veh.stored = "garage"
      syncVehicleListStatus()
        StaffMenu.data.skipVehicleServerCheck = true
        StaffMenu.vehicleActions.refresh(true)
    end)
    StaffMenu.vehicleActions.Button(":siren: Mettre en fourrière", "Envoyer ce véhicule à la fourrière (payant pour le récupérer)", nil, "chevron", not isPersonal or isInPound or not canState, function()
        TriggerServerEvent(setStateEvent, veh.plate, "fourriere")
        veh.stored = "fourriere"
      syncVehicleListStatus()
        StaffMenu.data.skipVehicleServerCheck = true
        StaffMenu.vehicleActions.refresh(true)
    end)

    -- Spawn le véhicule - Disabled if already spawned (out)
    StaffMenu.vehicleActions.Button(":car: Spawn le véhicule", "Faire apparaître le véhicule à la position actuelle du joueur", nil, "chevron", isSpawned or not canSpawn, function()
        if lookupMode then
            TriggerServerEvent("vfw:staff:lookupSpawnVehicle", veh.plate)
        else
            TriggerServerEvent("vfw:staff:spawnVehicleForPlayer", StaffMenu.data.selectedPlayer, veh.plate)
        end
        veh.stored = "sorti"
      syncVehicleListStatus()
        StaffMenu.data.skipVehicleServerCheck = true
        Wait(500)
        StaffMenu.vehicleActions.refresh(true)
    end)

    -- En lookup mode (Outils Staff) on n'affiche que les actions de stockage
    if StaffMenu.data.vehsLookupMode then return end

    StaffMenu.vehicleActions.Separator(":wrench: Actions")
    -- TP au véhicule - Disabled if not spawned
    StaffMenu.vehicleActions.Button("TP au véhicule", "Se téléporter à l'emplacement du véhicule spawné", nil, "chevron", not isSpawned or not VFW.PlayerGlobalData.permissions["staff_vehicle_tp"], function()
        TriggerServerEvent("vfw:staff:tpToVehicle", veh.plate)
    end)

    StaffMenu.vehicleActions.Button("Supprimer le véhicule", "Supprimer le véhicule actuellement spawné de la carte", nil, "chevron", not isSpawned or not VFW.PlayerGlobalData.permissions["staff_vehicle_delete_spawned"], function()
        TriggerServerEvent("vfw:staff:deleteSpawnedVehicle", veh.plate)
        veh.stored = "garage"
      syncVehicleListStatus()
        StaffMenu.data.skipVehicleServerCheck = true
        StaffMenu.vehicleActions.refresh(true)
    end)

    StaffMenu.vehicleActions.Button("Mettre le plein", "Remplir le réservoir du véhicule à 100%", nil, "chevron",
        not isSpawned or not VFW.PlayerGlobalData.permissions["alt_repair_vehicle"], function()
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

        if not targetVehicle then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule doit être spawné pour faire le plein."
          })
            return
        end

        if not NetworkGetEntityIsNetworked(targetVehicle) then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule n'est pas synchronisé sur le réseau."
          })
            return
        end

        local netId = NetworkGetNetworkIdFromEntity(targetVehicle)
        local result = TriggerServerCallback("vfw:action:run", {
            action = "vehicle:refuel",
            ent = { netId = netId, entType = 2 },
            permission = "alt_repair_vehicle"
      })

        if result and result.ok then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
                message = "Plein effectué."
          })
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Impossible de faire le plein."
          })
        end
    end)

    -- Separator for key management
    StaffMenu.vehicleActions.Separator(":key: Gestion des clés")

    -- Clés temporaires (reboot)
    StaffMenu.vehicleActions.Button("Clés temporaires (reboot)", "Disparaissent au redémarrage", nil, "chevron",
        not VFW.PlayerGlobalData.permissions["vehicle_keys_temp"], function()
        -- Trouver le véhicule spawné avec cette plaque
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
                    message = "Le véhicule n'est pas synchronisé sur le réseau."
              })
            else
                local netId = NetworkGetNetworkIdFromEntity(targetVehicle)
                local result = TriggerServerCallback("vfw:action:run", {
                    action = "vehicle:getKeysTemp",
                    ent = { netId = netId, entType = 2 },
                    permission = "vehicle_keys_temp"
              })

                if result and result.ok then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
                        message = "Vous avez pris les clés temporaires du véhicule."
                  })
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                        message = "Impossible de récupérer les clés."
                  })
                end
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule doit être spawné pour prendre les clés."
          })
        end
    end)

    -- Clés permanentes
    StaffMenu.vehicleActions.Button("Clés permanentes", "Persistent après redémarrage", nil, "chevron",
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
                    message = "Le véhicule n'est pas synchronisé sur le réseau."
              })
            else
                local netId = NetworkGetNetworkIdFromEntity(targetVehicle)
                local result = TriggerServerCallback("vfw:action:run", {
                    action = "vehicle:getKeys",
                    ent = { netId = netId, entType = 2 },
                    permission = "vehicle_keys_permanent"
              })

                if result and result.ok then
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Véhicules',
                        message = "Vous avez pris les clés permanentes du véhicule."
                  })
                else
                    VFW.ShowNotification({
                        type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                        message = "Impossible de récupérer les clés."
                  })
                end
            end
        else
            VFW.ShowNotification({
                type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Véhicules',
                message = "Le véhicule doit être spawné pour prendre les clés."
          })
        end
    end)

    -- Transférer le véhicule
    StaffMenu.vehicleActions.Button("Transférer le véhicule", "Changer le propriétaire", nil, "chevron",
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

-- Event to refresh vehicle actions menu after spawn
RegisterNetEvent("vfw:staff:refreshVehicleActionsMenu", function(newState)
    if StaffMenu.vehicleActions and StaffMenu.data.selectedVehicle then
        if newState then
            StaffMenu.data.selectedVehicle.stored = newState
        end
        StaffMenu.data.skipVehicleServerCheck = true
        if StaffMenu.vehicleActions.opened then
            StaffMenu.vehicleActions.refresh(true)
        end
    end
end)

local function getVehsHash(vehList)
    if not vehList then return "" end
    local hash = ""
  for _, veh in ipairs(vehList) do
        hash = hash .. (veh.plate or "") .. (tostring(veh.stored) or "") .. ";"
  end
    return hash
end

CreateThread(function()
    local lastHashOwned, lastHashJob, lastHashFaction = "", "", ""

  while true do
        Wait(2000)

        if not StaffMenu.data.selectedPlayer then
            goto continue
        end

        local ownedOpen = StaffMenu.vehs_owned and StaffMenu.vehs_owned.opened
        local jobOpen = StaffMenu.vehs_job and StaffMenu.vehs_job.opened
        local factionOpen = StaffMenu.vehs_faction and StaffMenu.vehs_faction.opened

        if ownedOpen or jobOpen or factionOpen then
            local newData = TriggerServerCallback("core:server:GetAllVehicle", StaffMenu.data.selectedPlayer) or { owned = {}, job = {}, faction = {} }

            local newHashOwned = getVehsHash(newData.owned)
            local newHashJob = getVehsHash(newData.job)
            local newHashFaction = getVehsHash(newData.faction)

            local hasChanges = false

            if ownedOpen and newHashOwned ~= lastHashOwned then
                hasChanges = true
                lastHashOwned = newHashOwned
            elseif jobOpen and newHashJob ~= lastHashJob then
                hasChanges = true
                lastHashJob = newHashJob
            elseif factionOpen and newHashFaction ~= lastHashFaction then
                hasChanges = true
                lastHashFaction = newHashFaction
            end

            if hasChanges then
                StaffMenu.data.vehsList = newData

                if ownedOpen then
                    StaffMenu.vehs_owned.refresh()
                elseif jobOpen then
                    StaffMenu.vehs_job.refresh()
                elseif factionOpen then
                    StaffMenu.vehs_faction.refresh()
                end
            end
        else
            lastHashOwned, lastHashJob, lastHashFaction = "", "", ""
      end

        ::continue::
    end
end)
