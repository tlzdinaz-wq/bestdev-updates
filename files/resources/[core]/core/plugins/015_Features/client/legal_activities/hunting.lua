---@class Hunting
local Hunting <const> = {}
Hunting.isHunting = false
Hunting.currentAnimal = nil
Hunting.currentBlip = nil
Hunting.zone = nil
Hunting.isSkinning = false

local VUI = exports["VUI"]

local menu = VUI:CreateMenu("Activité de chasse", "legal_activity", true)
local menuIsOpen = false

menu.OnClose(function()
    menuIsOpen = false
end)

menu.OnOpen(function()
    menuIsOpen = true
    if not Hunting.zone then
        menu.close()
    end

    if not Hunting.isHunting then
        menu.Button("Commencer l'activité", nil, nil, "chevron", false, function()
            TriggerServerEvent("core:hunting:server:start", Hunting.zone)
            menu.close()
        end)
    else
        menu.Button("Terminer l'activité", nil, nil, "chevron", false, function()
            TriggerServerEvent("core:hunting:server:stop")
            menu.close()
        end)
    end
end)

--- Attend qu'une entité (véhicule, ped, etc.) soit streamée localement à partir de son netId.
--- @param networkId number
--- @return number entity (0 si timeout)
local function awaitEntity(networkId)
    if not networkId or networkId == 0 then return 0 end
    for _ = 1, 100 do
        if NetworkDoesEntityExistWithNetworkId(networkId) then
            local ent = NetworkGetEntityFromNetworkId(networkId)
            if ent ~= 0 and DoesEntityExist(ent) then
                return ent
            end
        end
        Wait(50)
    end
    return 0
end

--- Crée un ped animal LOCAL UNIQUEMENT (invisible aux autres joueurs).
--- Évite les collisions de network ownership entre 2 chasseurs dans la même zone.
--- @param animalName string Hash key (ex: "a_c_deer")
--- @param position vector3
--- @return number ped (0 si échec)
local function spawnLocalAnimal(animalName, position)
    local hash = GetHashKey(animalName)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return 0
    end

    RequestModel(hash)
    local waited = 0
    while not HasModelLoaded(hash) and waited < 50 do
        Wait(50)
        waited = waited + 1
    end
    if not HasModelLoaded(hash) then
        return 0
    end

    -- isNetwork=false, thisScriptCheck=false : ped strictement local.
    local ped = CreatePed(26, hash, position.x, position.y, position.z, 90.0, false, false)
    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(ped) then
        return 0
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedConfigFlag(ped, 17, true)
    TaskWanderInArea(ped, position.x, position.y, position.z, 10.0, 2.0, 3.0)

    return ped
end

function Hunting.start()
    CreateThread(function()
        while Hunting.isHunting do
            if Hunting.currentAnimal and DoesEntityExist(Hunting.currentAnimal) then
                local ped <const> = PlayerPedId()
                local coords <const> = GetEntityCoords(ped)

                local animalCoords <const> = GetEntityCoords(Hunting.currentAnimal)
                local isEntityDead <const> = IsEntityDead(Hunting.currentAnimal)
                local deathCause <const> = GetPedCauseOfDeath(Hunting.currentAnimal)
                local musketHash <const> = GetHashKey("WEAPON_MUSKET")

                if #(coords - animalCoords) < 3.0 and isEntityDead and deathCause == musketHash and not Hunting.isSkinning then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour dépecer l'animal.")

                    if VFW.Interact.JustReleased(0, 51) then
                        Hunting.isSkinning = true
                        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)

                        local timeout = 0
                        while GetSelectedPedWeapon(ped) ~= GetHashKey("WEAPON_UNARMED") and timeout < 100 do
                            Wait(50)
                            timeout = timeout + 1
                        end

                        local knifeHash <const> = GetHashKey("prop_knife")
                        VFW.Streaming.RequestModel(knifeHash)
                        local knife <const> = CreateObject(knifeHash, coords.x, coords.y, coords.z, false, false, false)
                        SetEntityAsMissionEntity(knife, true, true)
                        AttachEntityToEntity(knife, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.03, 0.0, -90.0, 0.0, 0.0,
                            true, true, false, true, 1, true)
                        SetModelAsNoLongerNeeded(knifeHash)

                        RequestAnimDict("anim@gangops@facility@servers@bodysearch@")
                        while not HasAnimDictLoaded("anim@gangops@facility@servers@bodysearch@") do
                            Wait(0)
                        end
                        TaskPlayAnim(ped, "anim@gangops@facility@servers@bodysearch@", "player_search", 8.0, -8.0, -1, 0,
                            0, false, false, false)

                        Citizen.SetTimeout(5000, function()
                            ClearPedTasks(ped)
                            if DoesEntityExist(knife) then
                                DetachEntity(knife, true, true)
                                DeleteEntity(knife)
                            end
                            TriggerServerEvent('core:hunting:server:collect')
                            Hunting.isSkinning = false
                        end)
                    end
                end
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while Hunting.isHunting do
            if Hunting.currentAnimal and DoesEntityExist(Hunting.currentAnimal) then
                if Hunting.currentBlip then
                    VFW.RemoveBlipInternal(Hunting.currentBlip)
                    Hunting.currentBlip = nil
                end

                local animalPosition <const> = GetEntityCoords(Hunting.currentAnimal)
                Hunting.currentBlip = VFW.CreateBlipInternal(animalPosition, 463, 59, 0.8, "Animal")
            end

            Wait(1000)
        end

        if Hunting.currentBlip then
            VFW.RemoveBlipInternal(Hunting.currentBlip)
            Hunting.currentBlip = nil
        end
    end)

    CreateThread(function()
        while Hunting.isHunting do
            local ped <const> = PlayerPedId()
            local currentWeapon <const> = GetSelectedPedWeapon(ped)
            local musketHash <const> = GetHashKey("WEAPON_MUSKET")

            if currentWeapon == musketHash then
                local isAiming <const> = IsPlayerFreeAiming(PlayerId())
                if isAiming then
                    local hasTarget, target <const> = GetEntityPlayerIsFreeAimingAt(PlayerId())
                    if hasTarget and IsEntityAPed(target) and IsPedAPlayer(target) then
                        DisablePlayerFiring(PlayerId(), true)
                    end
                end
            end

            Wait(0)
        end
    end)
end

CreateThread(function()
    for zone, data in pairs(Config.hunting.zones) do
        VFW.CreateBlipRadius(data.zonePosition, 3000.0, 463, 24, 0.6, "Zone de chasse", 100, 24)
        VFW.CreateBlipInternal(data.position, 463, 59, 0.6, "Chasse")

        if data.zone then
            data.zone:onPointInOut(PolyZone.getPlayerPosition, function(isPointInside, point)
                if isPointInside then
                    Hunting.zone = zone
                else
                    Hunting.zone = nil

                    if Hunting.isHunting then
                        TriggerServerEvent("core:hunting:server:stop")
                    else
                        local ped <const> = PlayerPedId()
                        local musketHash <const> = GetHashKey("WEAPON_MUSKET")
                        if HasPedGotWeapon(ped, musketHash, false) then
                            if GetSelectedPedWeapon(ped) == musketHash then
                                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                            end
                            TriggerServerEvent("core:hunting:server:removeWeapon")
                            VFW.ShowNotification({
                                type = "ROUGE",
                                content = "Vous ne pouvez pas conserver le mousquet en dehors de la zone de chasse.",
                            })
                        end
                    end
                end
            end)
        end

        if data.ped then
            -- Ensure collision is loaded so the ped doesn't float
            RequestCollisionAtCoord(data.ped.position.x, data.ped.position.y, data.ped.position.z)
            local colAttempts = 0
            while not HasCollisionLoadedAroundEntity(PlayerPedId()) and colAttempts < 20 do
                RequestCollisionAtCoord(data.ped.position.x, data.ped.position.y, data.ped.position.z)
                Wait(50)
                colAttempts = colAttempts + 1
            end

            local ped <const> = cEntity.Manager:CreatePedLocal(data.ped.model,
                vector3(data.ped.position.x, data.ped.position.y, data.ped.position.z), data.ped.position.w)
            local pedId <const> = ped:getEntityId()

            PlaceObjectOnGroundProperly(pedId)
            ped:setFreeze(true)
            SetEntityInvincible(pedId, true)
            SetBlockingOfNonTemporaryEvents(pedId, true)
            TaskStartScenarioInPlace(pedId, "WORLD_HUMAN_CLIPBOARD", 0, true)
            GiveWeaponToPed(pedId, GetHashKey("weapon_musket"), 250, true, true)

            CreateThread(function()
                while true do
                    local playerPed <const> = PlayerPedId()
                    local playerCoords <const> = GetEntityCoords(playerPed)
                    local pedCoords <const> = GetEntityCoords(pedId)
                    local distance <const> = #(playerCoords - pedCoords)

                    if distance < 2.5 and not menuIsOpen then
                        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour parler")

                        if VFW.Interact.JustPressed(0, 38) then
                            menu.open()
                        end
                    end

                    Wait(0)
                end
            end)
        end
    end

    CreateThread(function()
        local sleep = 1000
        while true do
            sleep = 1000
            for k, seller in pairs(Config.hunting.sellers) do
                local playerPed <const> = PlayerPedId()
                local playerCoords <const> = GetEntityCoords(playerPed)

                local distance <const> = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(seller.position.x, seller.position.y, seller.position.z))

                if distance < 2.5 then
                    sleep = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour vendre")

                    if VFW.Interact.JustPressed(0, 38) then
                        local itemsToSell = TriggerServerCallback("core:legal_activities:hunting:getMyMeats")
                        SendNUIMessage({
                            action = "legal_activities:resell:open",
                            data = {
                                type = "hunting",
                                items = itemsToSell
                            }
                        })
                        VFW.Nui.Focus(true, false)
                        FreezeEntityPosition(PlayerPedId(), true)
                    end
                end
            end

            Wait(sleep)
        end
    end)



    RegisterNuiCallback("legal_activities:resell:close:hunting", function(data, cb)
        VFW.Nui.Focus(false)
        FreezeEntityPosition(PlayerPedId(), false)
        cb("ok")
    end)

    RegisterNuiCallback("legal_activities:resell:sell:hunting", function(data, cb)
        TriggerServerEvent("core:legal_activities:hunting:resell", data.name, data.count, data.paymentType)

        cb("ok")
    end)
end)


RegisterNetEvent("core:hunting:client:start", function(position, animalName, vehicleNetId)
    if Hunting.isHunting then
        return
    end

    Hunting.isHunting = true

    local ped <const> = spawnLocalAnimal(animalName, position)
    if ped == 0 then
        Hunting.isHunting = false
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Erreur lors du spawn de l'animal. Réessayez.",
        })
        return
    end

    -- Attendre que le véhicule soit streamé localement avant d'essayer d'unlock les
    -- portes / set le fuel, sinon ces appels échouent silencieusement quand le client
    -- n'a pas encore l'entité (race avec CreateVehicleServerSetter).
    local vehicle <const> = awaitEntity(vehicleNetId)
    if vehicle ~= 0 then
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        SetVehicleDoorsLocked(vehicle, 1)
        if VehicleFuel then
            VehicleFuel.Set(vehicle, 100.0, true)
        else
            SetVehicleFuelLevel(vehicle, 100.0)
        end
    end

    Hunting.currentBlip = VFW.CreateBlipInternal(position, 463, 59, 0.8, "Animal")
    Hunting.currentAnimal = ped
    Hunting.start()

    VFW.ShowNotification({
        type = "VERT",
        content = "Un animal vient d'apparaître, abattez-le avec votre mousquet et ramassez-le.",
    })
end)

RegisterNetEvent("core:hunting:client:collected", function()
    -- L'animal local est encore là (cadavre dépecé) — on le delete pour propre.
    if Hunting.currentAnimal and DoesEntityExist(Hunting.currentAnimal) then
        DeleteEntity(Hunting.currentAnimal)
    end
    Hunting.currentAnimal = nil
    Hunting.isSkinning = false

    if Hunting.currentBlip then
        VFW.RemoveBlipInternal(Hunting.currentBlip)
        Hunting.currentBlip = nil
    end
end)

RegisterNetEvent("core:hunting:client:new", function(position, animalName)
    if not Hunting.isHunting then
        return
    end

    if Hunting.currentAnimal and DoesEntityExist(Hunting.currentAnimal) then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Vous devez ramasser l'animal actuel avant d'en chasser un nouveau.",
        })
        return
    end

    local ped <const> = spawnLocalAnimal(animalName, position)
    if ped == 0 then
        VFW.ShowNotification({
            type = "ROUGE",
            content = "Erreur lors du spawn de l'animal. Réessayez.",
        })
        return
    end

    Hunting.currentBlip = VFW.CreateBlipInternal(position, 463, 59, 0.8, "Animal")
    Hunting.currentAnimal = ped
end)

RegisterNetEvent("core:hunting:client:stop", function()
    if not Hunting.isHunting then
        return
    end

    Hunting.isHunting = false
    Hunting.isSkinning = false

    -- L'animal est local : on le delete pour pas laisser de cadavre fantôme.
    if Hunting.currentAnimal and DoesEntityExist(Hunting.currentAnimal) then
        DeleteEntity(Hunting.currentAnimal)
    end
    Hunting.currentAnimal = nil

    if Hunting.currentBlip then
        VFW.RemoveBlipInternal(Hunting.currentBlip)
        Hunting.currentBlip = nil
    end

    -- Le serveur retire le mousquet de l'inventaire mais si le joueur l'a en main,
    -- l'arme reste équipée visuellement. On force le déséquipement côté client.
    -- L'inventaire custom du framework peut redonner l'arme automatiquement après
    -- un seul SetCurrentPedWeapon, donc on retry plusieurs fois sur quelques frames.
    CreateThread(function()
        local musketHash <const> = GetHashKey("WEAPON_MUSKET")
        for _ = 1, 20 do
            local ped = PlayerPedId()
            if HasPedGotWeapon(ped, musketHash, false) then
                RemoveWeaponFromPed(ped, musketHash)
            end
            if GetSelectedPedWeapon(ped) == musketHash then
                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            end
            Wait(50)
        end
    end)

    VFW.ShowNotification({
        type = "VERT",
        content = "Vous avez arrêté l'activité de chasse.",
    })
end)

AddEventHandler("gameEventTriggered", function(name, args)
    if name == "CEventNetworkEntityDamage" then
        local victim <const> = args[1]
        local attacker <const> = args[2]
        local weapon <const> = args[7]

        if DoesEntityExist(victim) and IsEntityAPed(victim) and IsPedAPlayer(victim) then
            if weapon == `WEAPON_MUSKET` then
                CancelEvent()
            end
        end
    end
end)
