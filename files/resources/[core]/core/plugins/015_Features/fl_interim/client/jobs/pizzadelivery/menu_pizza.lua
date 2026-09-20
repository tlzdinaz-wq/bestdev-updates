local VUI = exports["VUI"]

local PizzaMenu = nil
local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end


local outfits = {
    {
        ['tshirt_1'] = 15,  -- T-shirt blanc
        ['tshirt_2'] = 0,
        ['torso_1'] = 12,   -- Tablier/Veste de cuisine
        ['torso_2'] = 0,
        ['arms'] = 1,       -- Bras manches courtes
        ['pants_1'] = 28,   -- Pantalon de cuisine noir
        ['pants_2'] = 0,
        ['shoes_1'] = 10,   -- Chaussures de cuisine
        ['shoes_2'] = 0,
        ['chain_1'] = 0,
        ['chain_2'] = 0,
        ['helmet_1'] = -1,  -- Pas de casque (ou toque si disponible)
        ['helmet_2'] = 0,
        ['glasses_1'] = 0,
        ['glasses_2'] = 0,
        ['decals_1'] = 0,
        ['decals_2'] = 0,
        ['mask_1'] = 0,
        ['mask_2'] = 0,
        ['bproof_1'] = 0,
        ['bproof_2'] = 0
    },
    {
        ['tshirt_1'] = 14,  -- T-shirt blanc
        ['tshirt_2'] = 0,
        ['torso_1'] = 27,   -- Tablier/Veste de cuisine
        ['torso_2'] = 0,
        ['arms'] = 0,       -- Bras manches courtes
        ['pants_1'] = 27,   -- Pantalon de cuisine noir
        ['pants_2'] = 0,
        ['shoes_1'] = 1,    -- Chaussures de cuisine
        ['shoes_2'] = 0,
        ['chain_1'] = 0,
        ['chain_2'] = 0,
        ['helmet_1'] = -1,
        ['helmet_2'] = 0,
        ['glasses_1'] = 0,
        ['glasses_2'] = 0,
        ['decals_1'] = 0,
        ['decals_2'] = 0,
        ['mask_1'] = 0,
        ['mask_2'] = 0,
        ['bproof_1'] = 0,
        ['bproof_2'] = 0
    }
}


local function checkNPCDistance()
    local POS = TriggerServerCallback("interim:pizza:getPositionsAll")
    if not POS or not POS.startplace then
        notify("ROUGE", "Position NPC non disponible.")
        return false
    end

    local ped = PlayerPedId()
    local pPos = GetEntityCoords(ped)
    local npcPos = vector3(POS.startplace.x, POS.startplace.y, POS.startplace.z)
    local dist = #(pPos - npcPos)
    local maxDist = POS.startplace_radius or 2.0

    if dist > maxDist then
        notify("ROUGE", "Vous êtes trop loin du pizzaiolo.")
        return false
    end

    return true
end

local function hasVehicleOut()
    local netId = TriggerServerCallback("interim:pizza:getVehicleNetId")
    return netId ~= false and netId ~= nil
end

local function getStockInfo()
    local current, max = TriggerServerCallback("interim:pizza:getStockCount")
    return current or 0, max or 10
end

local trunkMarkerThread = nil

local function removeTrunkMarker()
    if trunkMarkerThread then
        trunkMarkerThread = nil
    end
end

local function requestVehicle()
    if not checkNPCDistance() then return false end

    local netId = TriggerServerCallback("interim:pizza:requestvehicle", {})

    if netId then
        notify("VERT", "Véhicule sorti.")


        return true
    else
        notify("ROUGE", "Impossible de sortir le véhicule.")
        return false
    end
end

local function storeVehicle()
    if not checkNPCDistance() then return false end

    local netId = TriggerServerCallback("interim:pizza:getVehicleNetId")
    if not netId then
        notify("ROUGE", "Aucun véhicule à ranger.")
        return false
    end

    removeTrunkMarker()

    if isCarryingPizza then
        isCarryingPizza = false
        ExecuteCommand("cancelemote")
    end

    TriggerServerEvent("interim:pizza:unregisterVehicle", netId)
    notify("VERT", "Véhicule rangé.")
    return true
end

local function createTrunkInteraction()
    removeTrunkMarker()

    local netId = TriggerServerCallback("interim:pizza:getVehicleNetId")
    if not netId then return end

    local ent = NetworkGetEntityFromNetworkId(netId)
    if not ent or not DoesEntityExist(ent) then return end

    trunkMarkerThread = true
    CreateThread(function()
        while trunkMarkerThread and isCarryingPizza do
            Wait(0)

            local veh = NetworkGetEntityFromNetworkId(netId)
            if not veh or not DoesEntityExist(veh) then
                break
            end

            local ped = PlayerPedId()
            local pPos = GetEntityCoords(ped)
            local vPos = GetEntityCoords(veh)
            local dist = #(pPos - vPos)

            if dist < 50.0 then
                if dist <= 2.5 then
                    VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour déposer la pizza dans le coffre")

                    if VFW.Interact.JustPressed(0, 38) then
                        local success = TriggerServerCallback("interim:pizza:canStockPizza")
                        if success then
                            isCarryingPizza = false
                            ExecuteCommand("cancelemote")

                            local cur, mx = getStockInfo()
                            notify("VERT", ("Pizza stockée (%d/%d)."):format(cur, mx))

                            removeTrunkMarker()
                        else
                            notify("ROUGE", "Impossible de déposer la pizza.")
                        end
                        if PizzaMenu then
                            PizzaMenu.refresh()
                        end
                    end
                end
            else
                Wait(200)
            end
        end
        trunkMarkerThread = nil
    end)
end

local function takePizza()
    if not checkNPCDistance() then return end

    if PlayerData.job and PlayerData.job.name and PlayerData.job.name ~= "unemployed" then
        notify("ROUGE", "Vous devez être sans emploi pour faire ce métier d'intérim.")
        return
    end

    if isCarryingPizza then
        notify("ROUGE", "Vous transportez déjà une pizza.")
        return
    end

    local vehOut = hasVehicleOut()
    if not vehOut then
        notify("ROUGE", "Vous devez sortir votre véhicule de livraison d'abord.")
        return
    end

    local current, max = getStockInfo()
    if current >= max then
        notify("ROUGE", ("Stock plein (%d/%d). Allez livrer !"):format(current, max))
        return
    end

    local pickup = TriggerServerCallback("interim:pizza:canPickupPizza")
    if not pickup then
        notify("ROUGE", "Impossible de prendre la pizza.")
        return
    end

    isCarryingPizza = true
    ExecuteCommand("e c")
    EmoteCommandStart("carrypizza", PlayerPedId())

    notify("VERT", "Pizza prise. Déposez-la dans le coffre du scooter.")

    if PizzaMenu then
        Wait(100)
        PizzaMenu.refresh()
    end

    createTrunkInteraction()
end

local function returnPizza()
    if not checkNPCDistance() then return end

    if not isCarryingPizza then
        notify("ROUGE", "Vous ne transportez aucune pizza.")
        return
    end

    local drop = TriggerServerCallback("interim:pizza:canDropPizza")
    if drop then
        isCarryingPizza = false
        ExecuteCommand("cancelemote")

        removeTrunkMarker()
        notify("VERT", "Pizza rendue.")

        if PizzaMenu then
            PizzaMenu.refresh()
        end
    else
        notify("ROUGE", "Impossible de rendre la pizza.")
    end
end

local function startDelivery()
    if not checkNPCDistance() then return end

    if PlayerData.job and PlayerData.job.name and PlayerData.job.name ~= "unemployed" then
        notify("ROUGE", "Vous devez être sans emploi pour faire ce métier d'intérim.")
        return
    end

    if StartPizzaDelivery and StartPizzaDelivery() then
        if PizzaMenu then
            Wait(500)
            PizzaMenu.refresh()
        end
    end
end

local function cancelDelivery()
    if CancelPizzaDelivery and CancelPizzaDelivery("user_cancel") then
        if PizzaMenu then
            Wait(500)
            PizzaMenu.refresh()
        end
    end
end

function CreatePizzaMenu()
    if PizzaMenu then return PizzaMenu end

    PizzaMenu = VUI:CreateMenu("PIZZERIA - GESTION", GetVUIBanner("pizza"), false)

    PizzaMenu.OnOpen(function()
        BuildPizzaMenu()
    end)

    PizzaMenu.OnClose(function()
        PizzaMenu.ClearItems()
    end)

    return PizzaMenu
end

local serviceOutfit = false

function BuildPizzaMenu()
    PizzaMenu.ClearItems()

    local vehOut = hasVehicleOut()
    local current, max = getStockInfo()
    local deliveryActive = IsDeliveryActive and IsDeliveryActive() or false

    PizzaMenu.Title("Gestion de la Pizzeria", "", "", "", nil)
    PizzaMenu.Separator(nil)

    if serviceOutfit then
        PizzaMenu.Button(
                "Déposer la tenue",
                "Déposez votre tenue de service",
                nil,
                nil,
                false,
                function()
                    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
                    TriggerEvent('skinchanger:loadSkin', skin or {})
                    serviceOutfit = false
                    PizzaMenu.refresh()
                end
        )
        PizzaMenu.Separator(nil)
    else
        PizzaMenu.Button(
                "Prendre la tenue",
                "Prenez votre tenue de service",
                nil,
                nil,
                false,
                function()

                    TriggerEvent('skinchanger:getSkin', function(skin)
                        -- skin.sex = 0 pour Homme, 1 pour Femme
                        if skin.sex == 0 then
                            TriggerEvent('skinchanger:loadClothes', skin, outfits[1])
                        else
                            TriggerEvent('skinchanger:loadClothes', skin, outfits[2])
                        end
                    end)
                    serviceOutfit = true
                    PizzaMenu.refresh()
                end)
    end

    if vehOut then
        PizzaMenu.Button(
            "Ranger le véhicule",
            "Rangez votre scooter de livraison",
            nil,
            nil,
            deliveryActive,
            function()
                if storeVehicle() then
                    Wait(500)
                    PizzaMenu.refresh()
                end
            end
        )
    else
        PizzaMenu.Button(
            "Sortir le véhicule",
            "Sortez votre scooter de livraison",
            nil,
            nil,
            false,
            function()
                if requestVehicle() then
                    Wait(500)
                    PizzaMenu.refresh()
                end
            end
        )
    end

    PizzaMenu.Separator(nil)

    local pizzaLabel = ("Stock: %d/%d"):format(current, max)
    local pizzaSubtitle = vehOut and "Prenez une pizza pour la déposer dans le coffre" or "Sortez d'abord votre véhicule"

    PizzaMenu.Button(
        "Prendre une pizza",
        pizzaSubtitle,
        pizzaLabel,
        nil,
        not vehOut or isCarryingPizza or current >= max,
        function()
            takePizza()
        end
    )

    PizzaMenu.Button(
        "Rendre une pizza",
        "Rendez la pizza que vous transportez",
        nil,
        nil,
        not isCarryingPizza,
        function()
            returnPizza()
        end
    )

    PizzaMenu.Separator(nil)

    if deliveryActive then
        PizzaMenu.Button(
            "Annuler les livraisons",
            "Annulez votre tournée en cours",
            nil,
            nil,
            false,
            function()
                cancelDelivery()
            end
        )
    else
        local deliverySubtitle = "Commencez votre tournée de livraison"
        if not vehOut then
            deliverySubtitle = "Sortez d'abord votre véhicule"
        elseif current < 1 then
            deliverySubtitle = "Prenez des pizzas d'abord"
        end

        PizzaMenu.Button(
            "Lancer les livraisons",
            deliverySubtitle,
            pizzaLabel,
            nil,
            not vehOut or current < 1,
            function()
                startDelivery()
            end
        )
    end
end

function TogglePizzaMenu()
    if not PizzaMenu then
        CreatePizzaMenu()
    end
    PizzaMenu.toggle()
end

function OpenPizzaMenu()
    if not PizzaMenu then
        CreatePizzaMenu()
    end
    PizzaMenu.open()
end

AddEventHandler("vfw:startko", function()
    removeTrunkMarker()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    removeTrunkMarker()
end)
