local headbagModel = "prop_money_bag_01"
local attachedBags = {}

local function AttachBagToPed(ped)
    RequestModel(headbagModel)
    while not HasModelLoaded(headbagModel) do Wait(10) end

    local bag = VFW.OneSync.CreateObject(headbagModel, GetEntityCoords(ped))
    AttachEntityToEntity(bag, ped, GetPedBoneIndex(ped, 12844), 0.2, 0.04, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
    attachedBags[ped] = bag
end

local function HasHeadbagItemClient()
    for _, item in pairs(VFW.PlayerData.inventory or {}) do
        if item.name and item.name:lower() == "sactete" and item.count and item.count > 0 then
            return true
        end
    end
    return false
end



-- Utilisation depuis l'inventaire : sélecteur de joueur dans un rayon
RegisterNetEvent("headbag:client:useFromInventory", function()
    if VFW.CloseInventory then VFW.CloseInventory() end

    local myPed = PlayerPedId()
    if IsPedInAnyVehicle(myPed, false) then
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible en véhicule." })
        return
    end

    local targetPlayerId = VFW.StartSelect(3.0, true)
    if not targetPlayerId then
        VFW.ShowNotification({ type = 'ROUGE', content = "Aucune cible à proximité." })
        return
    end

    local targetPed = GetPlayerPed(targetPlayerId)
    if targetPed and DoesEntityExist(targetPed) and Entity(targetPed).state.isBagged then
        VFW.ShowNotification({ type = 'ROUGE', content = "Cette personne a déjà un sac sur la tête." })
        return
    end

    local targetServerId = GetPlayerServerId(targetPlayerId)
    if not targetServerId or targetServerId == 0 then
        VFW.ShowNotification({ type = 'ROUGE', content = "Joueur introuvable." })
        return
    end

    TriggerServerEvent("headbag:server:apply", targetServerId)
end)

RegisterNetEvent("vfw:headbag:notify")
AddEventHandler("vfw:headbag:notify", function(message)
    VFW.ShowNotification({
        type = 'ROUGE',
        content = message
    })
end)

-- NOTE: Le bouton "Mettre un sac" est dans ped_context_menu.lua > Actions Faction (subMenuFactionOther)

-- NPC: aplicar prop
RegisterNetEvent("headbag:applyToPed")
AddEventHandler("headbag:applyToPed", function(ped)
    if DoesEntityExist(ped) then
        Entity(ped).state:set("isBagged", true, true)

        AttachBagToPed(ped)

    end
end)

-- NPC: quitar prop
RegisterNetEvent("headbag:removeFromPed")
AddEventHandler("headbag:removeFromPed", function(ped)
    if DoesEntityExist(ped) then
        Entity(ped).state:set("isBagged", false, true)

        if attachedBags[ped] then
            DeleteEntity(attachedBags[ped])
            attachedBags[ped] = nil
        end
    end
end)

-- Jugador: textura
RegisterNetEvent("headbag:apply")
AddEventHandler("headbag:apply", function()
    isBagged = true
    Entity(PlayerPedId()).state:set("isBagged", true, true)

    local ped = PlayerPedId()
    AttachBagToPed(ped)

    -- Failsafe: después de 10 minutos, permitir auto-remover
    Citizen.CreateThread(function()
        Citizen.Wait(10 * 60 * 1000) -- 10 minutos en ms
        if isBagged then
            TriggerEvent("headbag:selfRemove")
        end
    end)
end)

RegisterNetEvent("headbag:selfRemove")
AddEventHandler("headbag:selfRemove", function()
    if isBagged then
        isBagged = false
        Entity(PlayerPedId()).state:set("isBagged", false, true)

        SetFollowPedCamViewMode(1) -- volver a tercera persona

        local ped = PlayerPedId()
        if attachedBags[ped] then
            DeleteEntity(attachedBags[ped])
            attachedBags[ped] = nil
        end

        -- Dar el ítem de vuelta al inventario
        TriggerServerEvent("headbag:server:selfRemoveGiveItem")

        VFW.ShowNotification({
            type = 'VERT',
            content = "Vous avez réussi à retirer votre capuche et l'avez rangée dans votre inventaire."
        })
    end
end)


RegisterNetEvent("headbag:remove")
AddEventHandler("headbag:remove", function()
    isBagged = false
    Entity(PlayerPedId()).state:set("isBagged", false, true)

    SetFollowPedCamViewMode(1) -- volver a tercera persona

    local ped = PlayerPedId()
    if attachedBags[ped] then
        DeleteEntity(attachedBags[ped])
        attachedBags[ped] = nil
    end
end)


local textureDict = "bag_overlay"
local textureName = "bag_view"

-- Render loop para textura
Citizen.CreateThread(function()
    RequestStreamedTextureDict(textureDict, true)
    while not HasStreamedTextureDictLoaded(textureDict) do
        Citizen.Wait(10)
    end

    while true do
        if isBagged then
            if GetFollowPedCamViewMode() ~= 4 then
                SetFollowPedCamViewMode(4)
            end
            DisableControlAction(0, 0xF1EFA2B2, true)
            DrawSprite(textureDict, textureName, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)








