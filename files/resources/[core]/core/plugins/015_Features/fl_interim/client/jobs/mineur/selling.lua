
local buyerBlip, buyerPed

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local minerSellingButtonId = generateUniqueID(8)

local isSelling = false
local function StartSell()
    if isSelling then
        notify("JAUNE", "Tu es déjà en train de vendre.")
        return
    end
    isSelling = true


    TriggerServerEvent("interim:miner:startSell")
    CreateThread(function()
        -- On prépare le visuel AVANT la boucle pour ne pas le recharger 60 fois par seconde
        instructionalButtons[minerSellingButtonId] = {{ label = "Arrêter la vente", control = 105 }}

        while isSelling do
            if IsControlJustPressed(0, 105) then
                TriggerServerEvent("interim:miner:stopSell")
                ClearPedTasks(PlayerPedId())
                isSelling = false
                break
            end
            Wait(0)
        end

        instructionalButtons[minerSellingButtonId] = nil
    end)
end

RegisterNetEvent("interim:miner:startSellingAnimation", function()
    CreateThread(function()
        local ped = PlayerPedId()
        local animDict = "mp_common"
        local animName = "givetake2_a"

        -- 1. Chargement du dictionnaire
        RequestAnimDict(animDict)
        local timeout = 0
        while not HasAnimDictLoaded(animDict) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end

        if HasAnimDictLoaded(animDict) then
            -- 2. Animation du JOUEUR (Toi)
            -- Flag 0 = Animation simple, haut du corps
            TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 2000, 0, 0, false, false, false)

            -- 3. Animation du PNJ ACHETEUR (buyerPed)
            -- On vérifie que le PNJ existe bien avant de lui demander de bouger
            if buyerPed and DoesEntityExist(buyerPed) then
                -- On joue exactement la même animation : il te tend la main aussi
                TaskPlayAnim(buyerPed, animDict, animName, 8.0, -8.0, 2000, 0, 0, false, false, false)
            end

            -- 4. Synchronisation visuelle
            -- On attend que les bras soient tendus (mi-animation)
            Wait(1000)

            -- (Ici l'argent est reçu techniquement)

            -- On laisse finir le mouvement (retrait du bras)
            Wait(1000)

            -- Nettoyage
            RemoveAnimDict(animDict)
        end
    end)
end)

RegisterNetEvent("interim:miner:stopSell", function()
    isSelling = false
end)



RegisterNetEvent("interim:miner:setBuyerZone", function(spot)
    if not spot then return end

    buyerBlip = AddBlipForCoord(spot.x, spot.y, spot.z)
    SetBlipSprite(buyerBlip, 605)
    SetBlipColour(buyerBlip, 46)
    SetBlipScale(buyerBlip, 0.5)
    SetBlipDisplay(buyerBlip, 4)
    SetBlipAsShortRange(buyerBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Mineur • Vente")
    EndTextCommandSetBlipName(buyerBlip)

    buyerPed = SpawnNpcsInterimJobs(
            spot.model,
            vector3(spot.x, spot.y, spot.z),
            spot.heading,
            "Appuyez sur ~INPUT_CONTEXT~ pour vendre vos minerais",
            function()
                StartSell()
            end
    )

end)

RegisterNetEvent("interim:miner:clearBlip", function()
    if buyerBlip then
        RemoveBlip(buyerBlip)
        buyerBlip = nil
    end
    if buyerPed then
        DeletePed(buyerPed)
        buyerPed = nil
    end
end)
RegisterNetEvent("nui:shops:open:miner", function(shopData)
    if not shopData then return end



    SendNUIMessage({
        action = "nui:shops:open",
        data = shopData
    })

    VFW.Nui.Focus(true)
end)

RegisterNetEvent("interim:miner:sellSuccess", function(data)
    if not data then return end
    notify("VERT", ("Tu as vendu tes minerais pour %s."):format(VFW.Math.FormatMoney(data.total)))

    CreateThread(function()
        Wait(300)
        TriggerServerEvent("interim:miner:requestShopRefresh")
    end)
end)

RegisterNetEvent("interim:miner:shopRefresh", function(shopData)
    if not shopData then return end

    SendNUIMessage({
        action = "nui:shops:open",
        data = shopData
    })
end)
