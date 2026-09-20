---@meta _
---@diagnostic disable: duplicate-doc-field

-- Vehicle Management Menu (top-level)

local vehicleMgmt = {
    driftEnabled = false
}

-- Helper: get closest vehicle (in vehicle or nearby within 1m)
local function getClosestVehicleNow()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(veh) then return veh end
    local coords = GetEntityCoords(ped)
    return GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 70)
end

--- .BuildVehicleManagementMenu
function StaffMenu.BuildVehicleManagementMenu()
    StaffMenu.vehicleManagement.ClearItems()
    local perms = VFW.StaffPerms()
    if VFW.HasStaffPerm("staff_menu") then
        perms = VFW.BuildFullPermissions()
    end

    -- === ACTIONS VÉHICULE ===
    local hasBasic = perms["spawn_veh"] or perms["delete_veh"] or perms["repair_veh"] or perms["alt_drift_mode"]
    if hasBasic then
        StaffMenu.vehicleManagement.Separator(":car: ACTIONS VÉHICULE")
    end

    if perms["spawn_veh"] then
        StaffMenu.vehicleManagement.Button(":car: SPAWN UN VÉHICULE", "Faire apparaître un véhicule par nom technique (ex: adder, zentorno)", nil, "chevron", false, function()
            local modelName = VFW.Nui.KeyboardInput(true, "Nom technique du véhicule")
            if not modelName or modelName == "" then return end

            local model = GetHashKey(modelName)
            if not (IsModelInCdimage(model) and IsModelAVehicle(model)) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Ce modèle n'est pas valide." })
                return
            end

            TriggerServerEvent("vfw:staff:menu:spawnVehicle", modelName)
        end)
    end

    if perms["delete_veh"] then
        StaffMenu.vehicleManagement.Button(":trash: SUPPRIMER UN VÉHICULE", "Supprimer le véhicule le plus proche ou tous ceux dans un rayon défini. Commande : /dv [radius]", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if DoesEntityExist(veh) then
                -- Use /dv 1 to properly handle cleanup (trunk eject, key removal, impound trigger)
                ExecuteCommand("dv 1")
            else
                local radius = VFW.Nui.KeyboardInput(true, "Aucun véhicule proche. Radius pour /dv ? (max 500)", "5")
                if not radius or radius == "" then return end
                radius = tonumber(radius)
                if not radius or radius <= 0 then return end
                if radius > 500 then radius = 500 end
                ExecuteCommand("dv " .. radius)
            end
        end)
    end

    if perms["repair_veh"] then
        StaffMenu.vehicleManagement.Button(":wrench: RÉPARER LE VÉHICULE", "Réparer entièrement le véhicule le plus proche (carrosserie, moteur, réservoir)", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if DoesEntityExist(veh) then
                SetVehicleFixed(veh)
                SetVehicleDeformationFixed(veh)
                SetVehicleEngineHealth(veh, 1000.0)
                SetVehicleBodyHealth(veh, 1000.0)
                SetVehiclePetrolTankHealth(veh, 1000.0)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Réparé." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
            end
        end)
    end

    if perms["repair_veh"] then
        StaffMenu.vehicleManagement.Button(":trash: NETTOYER LE VÉHICULE", "Supprimer la saleté et les décalcomanies du véhicule le plus proche", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if DoesEntityExist(veh) then
                SetVehicleDirtLevel(veh, 0.0)
                WashDecalsFromVehicle(veh, 1.0)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Nettoyé." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
            end
        end)
    end

    if perms["alt_repair_vehicle"] then
        StaffMenu.vehicleManagement.Button(":car: METTRE LE PLEIN", "Remplir le réservoir du véhicule le plus proche à 100%", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end

            if not NetworkGetEntityIsNetworked(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Le véhicule n'est pas synchronisé sur le réseau." })
                return
            end

            local netId = NetworkGetNetworkIdFromEntity(veh)
            local result = TriggerServerCallback("vfw:action:run", {
                action = "vehicle:refuel",
                ent = { netId = netId, entType = 2 },
                permission = "alt_repair_vehicle"
          })

            if result and result.ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Plein effectué." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Impossible de faire le plein." })
            end
        end)
    end

    if perms["alt_drift_mode"] then
        local driftLabel = vehicleMgmt.driftEnabled and ":car: MODE DRIFT (ON)" or ":car: MODE DRIFT (OFF)"
      StaffMenu.vehicleManagement.Button(driftLabel, "Activer/désactiver le mode drift sur votre véhicule actuel", nil, "chevron", false, function()
            vehicleMgmt.driftEnabled = not vehicleMgmt.driftEnabled
            VFW.ShowNotification({
                type = 'STAFF', variant = 'INFO', subtitle = 'Véhicule',
                message = "Mode drift " .. (vehicleMgmt.driftEnabled and "activé" or "désactivé") .. "."
          })
            StaffMenu.vehicleManagement.refresh()
        end)
    end

    -- === TÉLÉPORTATION VÉHICULE ===
    local hasTp = perms["bring_vehicle"] or perms["goto_vehicle"]
    if hasTp then
        StaffMenu.vehicleManagement.Separator(":pin: TÉLÉPORTATION VÉHICULE")
    end

    if perms["bring_vehicle"] then
        StaffMenu.vehicleManagement.Button(":back: BRING VÉHICULE", "Téléporter un véhicule jusqu'à vous en entrant sa plaque d'immatriculation", nil, "chevron", false, function()
            local plate = VFW.Nui.KeyboardInput(true, "Plaque du véhicule")
            if not plate or plate == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Cette plaque n'est pas valide." })
                return
            end
            TriggerServerEvent("vfw:staff:bringVehicle", plate)
        end)
    end

    if perms["goto_vehicle"] then
        StaffMenu.vehicleManagement.Button(":arrow: GOTO VÉHICULE", "Se téléporter sur un véhicule en entrant sa plaque d'immatriculation", nil, "chevron", false, function()
            local plate = VFW.Nui.KeyboardInput(true, "Plaque du véhicule")
            if not plate or plate == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Cette plaque n'est pas valide." })
                return
            end
            TriggerServerEvent("vfw:staff:gotoVehicle", plate)
        end)
    end

    -- === MODIFICATIONS TEMPORAIRES ===
    local hasTemp = perms["upgrade_veh"] or perms["setcarcolor"] or perms["change_plate"]
    if hasTemp then
        StaffMenu.vehicleManagement.Separator(":bolt: MODIFICATIONS TEMPORAIRES")
    end

    if perms["upgrade_veh"] then
        StaffMenu.vehicleManagement.Button(":arrow: AMÉLIORER TEMPORAIREMENT", "Appliquer les mods max au véhicule proche, réinitialisé au redémarrage", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if DoesEntityExist(veh) then
                SetVehicleModKit(veh, 0)
                SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false)
                SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false)
                SetVehicleMod(veh, 13, GetNumVehicleMods(veh, 13) - 1, false)
                SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false)
                SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false)
                ToggleVehicleMod(veh, 18, true)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Améliorations temporaires appliquées." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
            end
        end)
    end

    if perms["setcarcolor"] then
        StaffMenu.vehicleManagement.Button(":palette: COULEUR TEMPORAIRE", "Changer la couleur du véhicule proche, réinitialisée au redémarrage", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            local pR, pG, pB = GetVehicleCustomPrimaryColour(veh)
            local sR, sG, sB = GetVehicleCustomSecondaryColour(veh)
            StaffMenu.vehicleManagement.ColorPicker(pR, pG, pB, sR, sG, sB,
                function(r, g, b)
                    if DoesEntityExist(veh) then
                        SetVehicleCustomPrimaryColour(veh, r, g, b)
                    end
                end,
                function(r, g, b)
                    if DoesEntityExist(veh) then
                        SetVehicleCustomSecondaryColour(veh, r, g, b)
                    end
                end
            )
        end)
    end

    if perms["change_plate"] then
        StaffMenu.vehicleManagement.Button(" PLAQUE TEMPORAIRE", "Changer la plaque du véhicule proche visuellement, sans enregistrement en base", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            local newPlate = VFW.Nui.KeyboardInput(true, "Nouvelle plaque (8 char max)")
            if not newPlate or newPlate == "" or #newPlate > 8 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Cette plaque n'est pas valide (8 char max)." })
                return
            end
            SetVehicleNumberPlateText(veh, newPlate)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Plaque changée : " .. newPlate .. "." })
        end)
    end

    -- === MODIFICATIONS DÉFINITIVES ===
    if perms["staff_custom_permanent"] then
        StaffMenu.vehicleManagement.Separator(":save: MODIFICATIONS DÉFINITIVES")

        StaffMenu.vehicleManagement.Button(":arrow: AMÉLIORER DÉFINITIF", "Appliquer les mods max et sauvegarder en base de données", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            -- Apply upgrades
            SetVehicleModKit(veh, 0)
            SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false)
            SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false)
            SetVehicleMod(veh, 13, GetNumVehicleMods(veh, 13) - 1, false)
            SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false)
            SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false)
            ToggleVehicleMod(veh, 18, true)
            -- Save via server
            local plate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
            local props = VFW.Game.GetVehicleProperties(veh)
            TriggerServerEvent("vfw:staff:saveVehicleCustom", plate, props)
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Améliorations sauvegardées." })
        end)

        StaffMenu.vehicleManagement.Button(":palette: COULEUR DÉFINITIVE", "Changer la couleur du véhicule proche et sauvegarder en base de données", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            local plate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
            local saveGen = 0
            local function debouncedSave()
                saveGen = saveGen + 1
                local gen = saveGen
                Citizen.SetTimeout(600, function()
                    if gen == saveGen and DoesEntityExist(veh) then
                        local props = VFW.Game.GetVehicleProperties(veh)
                        TriggerServerEvent("vfw:staff:saveVehicleCustom", plate, props)
                    end
                end)
            end
            local pR, pG, pB = GetVehicleCustomPrimaryColour(veh)
            local sR, sG, sB = GetVehicleCustomSecondaryColour(veh)
            StaffMenu.vehicleManagement.ColorPicker(pR, pG, pB, sR, sG, sB,
                function(r, g, b)
                    if DoesEntityExist(veh) then
                        SetVehicleCustomPrimaryColour(veh, r, g, b)
                        debouncedSave()
                    end
                end,
                function(r, g, b)
                    if DoesEntityExist(veh) then
                        SetVehicleCustomSecondaryColour(veh, r, g, b)
                        debouncedSave()
                    end
                end
            )
        end)

        StaffMenu.vehicleManagement.Button(" PLAQUE DÉFINITIVE", "Changer la plaque du véhicule proche et sauvegarder en base de données", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            local newPlate = VFW.Nui.KeyboardInput(true, "Nouvelle plaque (8 char max)")
            if not newPlate or newPlate == "" or #newPlate > 8 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Cette plaque n'est pas valide." })
                return
            end
            local oldPlate = VFW.Math.Trim(GetVehicleNumberPlateText(veh))
            local success = TriggerServerCallback("vfw:vehicle:changePlate", oldPlate, newPlate)
            if success then
                SetVehicleNumberPlateText(veh, newPlate)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = "Plaque définitive : " .. newPlate .. "." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Plaque déjà utilisée ou véhicule introuvable en BDD." })
            end
        end)
    end

    -- === CLÉS ===
    local hasKeys = perms["vehicle_keys_temp"] or perms["vehicle_keys_permanent"]
    if hasKeys then
        StaffMenu.vehicleManagement.Separator(":key: CLÉS")
    end

    if perms["vehicle_keys_temp"] then
        StaffMenu.vehicleManagement.Button(":key: CLÉS TEMPORAIRES", "Donner les clés du véhicule proche à un joueur, valable jusqu'au redémarrage", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            if not NetworkGetEntityIsNetworked(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Le véhicule n'est pas synchronisé sur le réseau." })
                return
            end
            local targetIdStr = VFW.Nui.KeyboardInput(true, "ID du joueur (vide = vous-même)")
            local targetId = tonumber(targetIdStr)
            if not targetId or targetId == 0 then
                targetId = GetPlayerServerId(PlayerId())
            end
            local netId = NetworkGetNetworkIdFromEntity(veh)
            local result = TriggerServerCallback("vfw:action:run", {
                action = "vehicle:getKeysTemp",
                ent = { netId = netId, entType = 2 },
                permission = "vehicle_keys_temp",
                target = targetId
            })
            if result and result.ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = result.msg or "Clés temporaires données." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = (result and result.err) or "Impossible de donner les clés." })
            end
        end)
    end

    if perms["vehicle_keys_permanent"] then
        StaffMenu.vehicleManagement.Button(":key: CLÉS PERMANENTES", "Donner les clés du véhicule proche à un joueur de façon permanente", nil, "chevron", false, function()
            local veh = getClosestVehicleNow()
            if not DoesEntityExist(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun véhicule proche." })
                return
            end
            if not NetworkGetEntityIsNetworked(veh) then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Le véhicule n'est pas synchronisé sur le réseau." })
                return
            end
            local targetIdStr = VFW.Nui.KeyboardInput(true, "ID du joueur (vide = vous-même)")
            local targetId = tonumber(targetIdStr)
            if not targetId or targetId == 0 then
                targetId = GetPlayerServerId(PlayerId())
            end
            local netId = NetworkGetNetworkIdFromEntity(veh)
            local result = TriggerServerCallback("vfw:action:run", {
                action = "vehicle:getKeys",
                ent = { netId = netId, entType = 2 },
                permission = "vehicle_keys_permanent",
                target = targetId
            })
            if result and result.ok then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Véhicule', message = result.msg or "Clés permanentes données." })
            else
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = (result and result.err) or "Impossible de donner les clés." })
            end
        end)
    end

    -- === ADMINISTRATION VÉHICULE ===
    local hasAdmin = perms["staff_vehicle_delete_bdd"] or perms["staff_custom"]
    if hasAdmin then
        StaffMenu.vehicleManagement.Separator(":settings: ADMINISTRATION")
    end

    if perms["staff_vehicle_delete_bdd"] then
        StaffMenu.vehicleManagement.Button(":trash: SUPPRIMER VÉH D'UN JOUEUR", "Supprimer définitivement un véhicule d'un joueur en base de données via son UUID", nil, "chevron", false, function()
            local uuid = VFW.Nui.KeyboardInput(true, "UUID du joueur")
            if not uuid or uuid == "" then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Cet UUID n'est pas valide." })
                return
            end
            local data = TriggerServerCallback("vfw:staff:getPlayerVehiclesByUUID", uuid)
            if not data or #data == 0 then
                VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Véhicule', message = "Aucun personnage ou véhicule trouvé." })
                return
            end
            StaffMenu._deleteVehData = data
            StaffMenu.deleteVehPlayerChars.open()
        end)
    end

    if perms["staff_custom"] then
        StaffMenu.vehicleManagement.Button(":wrench: MENU CUSTOMS AVANCÉ", "Ouvrir le menu de customisation avancée d'un véhicule (tuning, extras, livrée)", nil, "chevron", false, function()
            StaffMenu.OpenVehicleCustomMenu(StaffMenu.vehicleManagement)
        end)
    end
end

-- === Sous-menus suppression véhicule joueur ===
StaffMenu.deleteVehPlayerChars.OnOpen(function()
    StaffMenu.deleteVehPlayerChars.ClearItems()
    local data = StaffMenu._deleteVehData
    if not data or #data == 0 then
        StaffMenu.deleteVehPlayerChars.Textbox("Aucun personnage trouvé.", "Erreur")
        return
    end
    for _, char in ipairs(data) do
        local vehCount = #char.vehicles
        StaffMenu.deleteVehPlayerChars.Button(char.name, vehCount .. (vehCount > 1 and " véhicules" or " véhicule"), nil, "chevron", false, function()
            StaffMenu._deleteVehCharVehicles = char.vehicles
            StaffMenu._deleteVehCharName = char.name
        end, StaffMenu.deleteVehPlayerList)
    end
end)

StaffMenu.deleteVehPlayerList.OnOpen(function()
    StaffMenu.deleteVehPlayerList.ClearItems()
    local vehicles = StaffMenu._deleteVehCharVehicles
    local charName = StaffMenu._deleteVehCharName or "Joueur"
  if not vehicles or #vehicles == 0 then
        StaffMenu.deleteVehPlayerList.Textbox("Aucun véhicule trouvé.", "Info")
        return
    end
    for _, veh in ipairs(vehicles) do
        StaffMenu.deleteVehPlayerList.Button(":car: " .. (veh.model or "Inconnu"), veh.plate .. " (" .. (veh.status or "?") .. ")", nil, "trash", false, function()
            local confirm = VFW.Nui.KeyboardInput(true, "Tapez OUI pour supprimer " .. veh.plate)
            if confirm and string.upper(confirm) == "OUI" then
                TriggerServerEvent("vfw:staff:removeVeh", veh.plate)
                for i, v in ipairs(vehicles) do
                    if v.plate == veh.plate then
                        table.remove(vehicles, i)
                        break
                    end
                end
                StaffMenu.deleteVehPlayerList.refresh()
            end
        end)
    end
end)

-- Drift mode thread for vehicle management menu toggle
CreateThread(function()
    while not VFW.IsPlayerLoaded() do Wait(100) end
    while true do
        Wait(150)
        if vehicleMgmt.driftEnabled then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                if GetPedInVehicleSeat(veh, -1) == ped then
                    SetVehicleReduceGrip(veh, IsControlPressed(0, 21))
                end
            end
        end
    end
end)
