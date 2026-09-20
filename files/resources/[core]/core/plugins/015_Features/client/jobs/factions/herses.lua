---@meta _
---@diagnostic disable: duplicate-doc-field

local burstCooldowns = {}
local STINGER_MODEL <const> = GetHashKey('p_ld_stinger_s')

local function BurstVehicleTyres(vehicle)
    if burstCooldowns[vehicle] then return end
    burstCooldowns[vehicle] = true

    for i = 0, 5 do
        if not IsVehicleTyreBurst(vehicle, i, false) then
            SetVehicleTyreBurst(vehicle, i, true, 1000.0)
        end
    end

    SetTimeout(5000, function()
        burstCooldowns[vehicle] = nil
    end)
end

-- Scan tous les objets stinger dans le monde (peu importe comment ils ont été placés)
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local playerCoords = GetEntityCoords(ped)
        local foundStinger = false

        local objects = GetGamePool('CObject')
        for _, obj in ipairs(objects) do
            if GetEntityModel(obj) == STINGER_MODEL then
                local herseCoords = GetEntityCoords(obj)

                -- Ne checker que les herses proches du joueur (50m)
                if #(playerCoords - herseCoords) < 50.0 then
                    foundStinger = true
                    local vehicles = GetGamePool('CVehicle')

                    for _, vehicle in ipairs(vehicles) do
                        local dist = #(herseCoords - GetEntityCoords(vehicle))

                        if dist < 3.0 then
                            local speed = GetEntitySpeed(vehicle) * 3.6
                            if speed > 5.0 then
                                BurstVehicleTyres(vehicle)
                            end
                        end
                    end
                end
            end
        end

        Wait(foundStinger and 100 or 500)
    end
end)

--- PutHerse
---@param obj any
local function PutHerse(obj)
    local coords, forward = GetEntityCoords(VFW.PlayerData.ped), GetEntityForwardVector(VFW.PlayerData.ped)
    local objCoords = (coords + forward * 2.5)
    local placed = false
    local heading = GetEntityHeading(VFW.PlayerData.ped)
    local objS = cEntity.Manager:CreateObject(obj, objCoords)

    objS:setPos(objCoords)
    objS:setHeading(heading)

    PlaceObjectOnGroundProperly(objS.id)

    while not placed do
        coords, forward = GetEntityCoords(VFW.PlayerData.ped), GetEntityForwardVector(VFW.PlayerData.ped)
        objCoords = (coords + forward * 2.5)
        objS:setPos(objCoords)
        PlaceObjectOnGroundProperly(objS.id)
        objS:setAlpha(170)
        SetEntityCollision(objS.id, false, true)

        if IsControlPressed(0, 190) then
            heading = heading + 0.5
        elseif IsControlPressed(0, 189) then
            heading = heading - 0.5
        end

        SetEntityHeading(objS.id, heading)

        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour placer l'objet\n~INPUT_FRONTEND_LEFT~ ou ~INPUT_FRONTEND_RIGHT~ Pour faire pivoter l'objet")

        if VFW.Interact.JustPressed(0, 38) then
            placed = true
        end

        Wait(0)
    end

    SetEntityCollision(objS.id, true, true)
    objS:resetAlpha()

    -- Le thread de detection scanne automatiquement par modele
end

--- PlayAnim
---@param dict any
---@param anim any
---@param flag any
local function PlayAnim(dict, anim, flag)
    if dict ~= "" then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Wait(1) end
        TaskPlayAnim(VFW.PlayerData.ped, dict, anim, 2.0, 2.0, -1, flag, 0, false, false, false)
        RemoveAnimDict(dict)
    end
end

RegisterNetEvent("core:UseHerse")
AddEventHandler("core:UseHerse", function()
    PutHerse('p_ld_stinger_s')
end)

---@param netid any
RegisterNetEvent("core:deletesyncItemC", function(netid)
    local obj = NetToObj(netid)

    if obj and DoesEntityExist(obj) then
        -- Supprimer le prop sabot si le véhicule en a un
        if bootProps then
            for veh, prop in pairs(bootProps) do
                if veh == obj or not DoesEntityExist(veh) then
                    if DoesEntityExist(prop) then
                        DeleteEntity(prop)
                    end
                    bootProps[veh] = nil
                end
            end
        end
        DeleteEntity(obj)
    else
        -- Véhicule déjà supprimé côté serveur, nettoyer les props orphelins
        if bootProps then
            for veh, prop in pairs(bootProps) do
                if not DoesEntityExist(veh) then
                    if DoesEntityExist(prop) then
                        DeleteEntity(prop)
                    end
                    bootProps[veh] = nil
                end
            end
        end
    end
end)

VFW.ContextAddButton("object", ":warning: Ramasser", function(object)
    return GetEntityModel(object) == STINGER_MODEL
end, function(object)
    PlayAnim("pickup_object", "pickup_low", 0)

    local netid = ObjToNet(object)

    TriggerServerEvent("core:deletesyncItem", netid)
    DeleteEntity(object)

    TriggerServerEvent("core:recupHerse")

    VFW.ShowNotification({
        type = 'JAUNE',
        content = "Vous avez ramassé une herse."
   })
end)
