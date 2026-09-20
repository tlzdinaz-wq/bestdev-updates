---@meta _
---@diagnostic disable: duplicate-doc-field

local belled = false
local open = false
--- .OpenUIProperty
---@param property any
function VFW.OpenUIProperty(property)
    open = not open
    belled = false
    VFW.PropertyMenuOpen = open
    VFW.Nui.Focus(open, false)
    SendNUIMessage({
        action = "nui:alternate-property-menu:visible",
        data = open
    })
    VFW.Nui.HudVisible(not open)
    if open then
        SetCursorLocation(0.5, 0.5)
        SendNUIMessage({
            action = "nui:alternate-property-menu:data",
            data = property
        })
    end
end

RegisterNUICallback("nui:alternate-property-menu:close", function()
    if not open then
        return
    end

    VFW.OpenUIProperty()
end)

RegisterNetEvent("vfw:property:reject", function()
    VFW.OpenUIProperty()
    VFW.ShowNotification({
        type= "ROUGE",
        content = "Personne n'a répondu"
    })
end)

---@param property any
RegisterNetEvent("vfw:property:accept", function(property)
    VFW.OpenUIProperty()
    if property.garageList then
        local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
        if vehicle and (vehicle ~= 0) then
            if GetPedInVehicleSeat(vehicle, -1) == VFW.PlayerData.ped then
                local model = GetEntityModel(vehicle)
                local props = VFW.Game.GetVehicleProperties(vehicle)
                -- Fallback plaque : state bag absent sur beaucoup d'imports / véhicules frais.
                local plate = (Entity(vehicle).state.VehicleProperties and Entity(vehicle).state.VehicleProperties.plate)
                    or (props and props.plate)
                    or VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))

                DoScreenFadeOut(500)
                Wait(500)

                local result
                -- Bug: propertyId n'existait pas → enterVehicle échouait toujours via accept.
                result, property = TriggerServerCallback("vfw:enterVehicle", VFW.ActualProperty, plate, GetMakeNameFromVehicleModel(model), props)
                if not result then
                    DoScreenFadeIn(500)
                    return
                end
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous devez sortir du véhicule ou être conducteur pour rentrer dans le garage."
                })
                return
            end
        end

        VFW.EnterGarage(property)
    else
        VFW.EnterHouse(property)
    end
end)

---@param id any
---@param property any
RegisterNetEvent("vfw:property:forceEnter", function(id, property)
    -- Close property menu if still open
    if open then
        VFW.OpenUIProperty()
    end
    VFW.ActualProperty = id
    if property.garageList then
        VFW.EnterGarage(property)
    else
        VFW.EnterHouse(property, true)
    end
end)

RegisterNUICallback("nui:property-menu:button", function(data, cb)
    if (data.type == "set_double" ) then
        VFW.OpenGestionProperty()
        local target = VFW.StartSelect(5.0, true)
        if not target then
            return
        end


        TriggerServerEvent("vfw:property:giveAccess", GetPlayerServerId(target), VFW.ActualProperty)
    end
end)

RegisterNUICallback("nui:alternate-property-menu:button", function(data)
    if not open then
        return
    end

    if data.type == "entrer" then
        VFW.OpenUIProperty()

        -- Check if player is in a vehicle to store it in garage
        local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
        if vehicle and (vehicle ~= 0) then
            if GetPedInVehicleSeat(vehicle, -1) == VFW.PlayerData.ped then
                local model = GetEntityModel(vehicle)
                local props = VFW.Game.GetVehicleProperties(vehicle)
                -- Ne plus exiger VehicleProperties (souvent absent sur imports) :
                -- plaque via state bag → props → native.
                local plate = (Entity(vehicle).state.VehicleProperties and Entity(vehicle).state.VehicleProperties.plate)
                    or (props and props.plate)
                    or VFW.Math.Trim(GetVehicleNumberPlateText(vehicle))

                -- Fade out before server despawns the vehicle
                DoScreenFadeOut(500)
                Wait(500)

                local result, enterProperty = TriggerServerCallback("vfw:enterVehicle", VFW.ActualProperty, plate, GetMakeNameFromVehicleModel(model), props)
                if not result then
                    DoScreenFadeIn(500)
                    return
                end

                VFW.EnterGarage(enterProperty)
                return
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous devez sortir du véhicule ou être conducteur pour rentrer dans le garage."
                })
                return
            end
        end

        local property = TriggerServerCallback("vfw:property:enter", VFW.ActualProperty)
        if not property then
            console.debug("Property not found")
            return
        end


        if property.garageList then
            VFW.EnterGarage(property)
        else
            VFW.EnterHouse(property)
        end
    elseif data.type == "sonner" then
        belled = true
        TriggerServerEvent("vfw:property:bell", VFW.ActualProperty)
    elseif data.type == "perquisitionner" then
        VFW.OpenUIProperty()

        -- Staff: enter directly like a normal entry (no animation, no state change)
        if VFW.IsInStaffMode and VFW.IsInStaffMode() then
            local property = TriggerServerCallback("vfw:property:enter", VFW.ActualProperty)
            if not property then
                return
            end
            if property.garageList then
                VFW.EnterGarage(property)
            else
                VFW.EnterHouse(property)
            end
            return
        end

        local valide, state = TriggerServerCallback("vfw:property:perquis", VFW.ActualProperty)
        if not valide then
            VFW.ShowNotification({
                type = "ROUGE",
                content = "Vous n'avez pas l'autorisation de perquisitionner"
            })
            return
        end

        FreezeEntityPosition(VFW.PlayerData.ped, true)
        Worlds.Zone.HideInteract(false)
        VFW.DisableInterations(true)

        local dict, anim
        if state then
            -- Fermeture : animation de verrouillage
            dict = "anim@heists@keycard@"
            anim = "exit"
        else
            -- Ouverture : animation bélier
            dict = "timetable@jimmy@doorknock@"
            anim = "knockdoor_idle"
        end
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(0) end
        TaskPlayAnim(VFW.PlayerData.ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
        RemoveAnimDict(dict)

        Wait(500)
        local ended = false
        CreateThread(function()
            while not ended do
                Wait(0)
                DisableAllControlActions(0)
            end
        end)

        local valide = VFW.Nui.ProgressBar(state and "Verrouillage de la porte ..." or "Perquisition ...", state and 3000 or 30000)

        if valide then
            TriggerServerEvent("vfw:property:perquisition", VFW.ActualProperty, not state)
        end

        ended = true
        VFW.DisableInterations(false)
        Worlds.Zone.HideInteract(true)
        FreezeEntityPosition(VFW.PlayerData.ped, false)
        ClearPedTasks(VFW.PlayerData.ped)
    end
end)

---@param propertyId any
---@param targetId number Player ID
---@param propertyName string Property name
RegisterNetEvent("vfw:property:bell", function(propertyId, targetId, propertyName)
    VFW.ShowNotification({
        type = "DYNASTY_BELL",
        content = "Quelqu'un sonne à votre " .. (propertyName or "propriété"),
        duration = 30
    })

    local choiced = false
    local bellDeadline = GetGameTimer() + 30000
    CreateThread(function()
        while not choiced do
            Wait(0)
            if GetGameTimer() > bellDeadline then
                choiced = true
                break
            end

            if IsControlJustPressed(0, 246) then
                TriggerServerEvent("vfw:property:accept", targetId, propertyId)
                choiced = true
                VFW.RemoveNotification()
            elseif IsControlJustPressed(0, 249) then
                TriggerServerEvent("vfw:property:reject", targetId)
                choiced = true
                VFW.RemoveNotification()
            end
        end
    end)
end)