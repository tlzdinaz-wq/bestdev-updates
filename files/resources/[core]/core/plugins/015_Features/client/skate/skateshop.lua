local display = false
local skateObject = nil
local skateSellerPed = nil
local shopCam = nil

-- Coordonnées pour le preview du skate (décalé à droite pour le panneau droit de l'UI)
local boardSpawnCoords = vector3(-1126.25, -1439.5317, 5.6483)
local boardSpawnRot = vector3(88.5249, 0.0000, -58.6148)
-- Caméra statique (pointe au centre de la scène, pas sur le skate)
local camCoords = vector3(-1125.58, -1438.30, 5.85)
local camPointAt = vector3(-1125.58, -1439.53, 5.65)

-- ==========================================
-- GESTIÓN DE LA TIENDA (UI)
-- ==========================================

function SetDisplay(bool)
    display = bool
    local data = bool and ConfigNewSkate.Skates or nil

    if bool then
        -- Créer une caméra statique pointant sur le skate
        shopCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(shopCam, camCoords.x, camCoords.y, camCoords.z)
        PointCamAtCoord(shopCam, camPointAt.x, camPointAt.y, camPointAt.z)
        SetCamActive(shopCam, true)
        RenderScriptCams(true, false, 0, true, false)
    end

    VFW.Nui.SkateShop(bool, data)

    if not bool then
        CleanupShop()
    end
end

-- Escuchamos el evento desde el NPC
RegisterNetEvent("skating:client:openShop", function()
    SetDisplay(true)
end)

function CleanupShop()
    if DoesEntityExist(skateObject) then
        DeleteEntity(skateObject)
        skateObject = nil
    end
    if shopCam then
        RenderScriptCams(false, false, 0, true, false)
        SetCamActive(shopCam, false)
        DestroyCam(shopCam, false)
        shopCam = nil
    end
end

-- ==========================================
-- NUI CALLBACKS
-- ==========================================

RegisterNUICallback("nui:SkateShop:previewSkate", function(data, cb)
    local modelName = data.model
    if DoesEntityExist(skateObject) then DeleteEntity(skateObject) end
    RequestModel(modelName)
    while not HasModelLoaded(modelName) do Wait(10) end
    skateObject = CreateObject(GetHashKey(modelName), boardSpawnCoords.x, boardSpawnCoords.y, boardSpawnCoords.z, false, false, false)
    SetEntityCoordsNoOffset(skateObject, boardSpawnCoords.x, boardSpawnCoords.y, boardSpawnCoords.z, true, true, true)
    SetEntityRotation(skateObject, boardSpawnRot.x, boardSpawnRot.y, boardSpawnRot.z, 2, true)
    SetEntityCollision(skateObject, false, false)
    FreezeEntityPosition(skateObject, true)
    cb("ok")
end)

local lastYaw, lastPitch = 0.0, 0.0
local firstLoad = true
RegisterNUICallback("nui:SkateShop:rotateSkate", function(data, cb)
    if DoesEntityExist(skateObject) then
        local p = (data.pitch or 0.0) + 0.0
        local y = (data.yaw or 0.0) + 0.0
        if firstLoad and p == 0.0 and y == 0.0 then
            firstLoad = false
            cb("ok")
            return
        end
        if math.abs(lastYaw - y) > 0.1 or math.abs(lastPitch - p) > 0.1 then
            SetEntityRotation(skateObject, p, 0.0, y, 1, true)
            lastYaw = y
            lastPitch = p
        end
    end
    cb("ok")
end)

RegisterNUICallback("purchaseSkate", function(data, cb)
    TriggerServerEvent("skating:server:buyItem", data.item)
    cb("ok")
end)

RegisterNUICallback("nui:SkateShop:closeUi", function(data, cb)
    SetDisplay(false)
    cb("ok")
end)

-- ==========================================
-- NPC VENDEDOR
-- ==========================================
CreateThread(function()
    local model = `u_m_y_sbike`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end

    skateSellerPed = CreatePed(4, model, -1125.68, -1440.94, 4.23, 302.01, false, true)
    SetEntityAsMissionEntity(skateSellerPed, true, true)
    SetBlockingOfNonTemporaryEvents(skateSellerPed, true)
    FreezeEntityPosition(skateSellerPed, true)
    SetEntityInvincible(skateSellerPed, true)

    RequestAnimDict("amb@world_human_leaning@male@wall@back@foot_up@idle_a")
    while not HasAnimDictLoaded("amb@world_human_leaning@male@wall@back@foot_up@idle_a") do Wait(0) end
    TaskPlayAnim(skateSellerPed, "amb@world_human_leaning@male@wall@back@foot_up@idle_a", "idle_a", 8.0, 0, -1, 1, 0, 0, 0, 0)

    VFW.ContextAddButton(skateSellerPed, "๋ ࣭Ouvrir le magasin de skate", function(ent)
        return #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ent)) < 3.0
    end, function()
        -- IMPORTANTE: Aquí activamos el evento
        TriggerEvent("skating:client:openShop")
    end, { icon = "skate" })

    SetModelAsNoLongerNeeded(model)

    -- ShowHelp + touche E pour ouvrir le shop
    CreateThread(function()
        while skateSellerPed and DoesEntityExist(skateSellerPed) do
            local wait = 1000
            if not display then
                local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(skateSellerPed))
                if dist < 3.0 then
                    wait = 0
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour ouvrir le magasin de skate")
                    if VFW.Interact.JustPressed(1, 38) then
                        SetDisplay(true)
                    end
                end
            end
            Wait(wait)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if skateSellerPed and DoesEntityExist(skateSellerPed) then
            DeleteEntity(skateSellerPed)
        end
        CleanupShop()
        VFW.Nui.Focus(false)
    end
end)
