local sellBlip, buyerPed

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function notify(t, msg)
    if VFW and VFW.ShowNotification then
        VFW.ShowNotification({ type = t or "JAUNE", content = msg })
    end
end

local lumberSellingButtonId = generateUniqueID(8)

local isSelling = false
local function StartSell()
    if isSelling then
        notify("JAUNE", "Tu es déjà en train de vendre.")
        return
    end
    isSelling = true


    TriggerServerEvent("interim:lumberjack:startSell")

    CreateThread(function()
        -- On prépare le visuel AVANT la boucle pour ne pas le recharger 60 fois par seconde
        instructionalButtons[lumberSellingButtonId] = {{ label = "Arrêter la vente", control = 105 }}

        while isSelling do
            if IsControlJustPressed(0, 105) then
                TriggerServerEvent("interim:lumberjack:stopSell")
                ClearPedTasks(PlayerPedId())
                isSelling = false
                break
            end
            Wait(0)
        end

        instructionalButtons[lumberSellingButtonId] = nil
    end)
end

RegisterNetEvent("interim:lumberjack:stopSell", function()
    isSelling = false
end)


local function createBuyerSpot(data)
    if not data or not data.buyerLocation then return end

    buyerPed = SpawnNpcsInterimJobs(
            data.pedBuyer,
            data.buyerLocation,
            data.buyerHeading,
            "Appuyez sur ~INPUT_CONTEXT~ pour vendre vos planches",
            function()
                StartSell()
            end
    )

    sellBlip = AddBlipForCoord(data.buyerLocation.x, data.buyerLocation.y, data.buyerLocation.z)
    SetBlipSprite(sellBlip, 605)
    SetBlipColour(sellBlip, 2)
    SetBlipScale(sellBlip, 0.5)
    SetBlipDisplay(sellBlip, 4)
    SetBlipAsShortRange(sellBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("~HUD_COLOUR_BLUE~[Intérim]~HUD_COLOUR_PURE_WHITE~ Bucheron • Vente")
    EndTextCommandSetBlipName(sellBlip)



end

RegisterNetEvent("interim:lumberjack:startSellingAnimation", function()
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

RegisterNetEvent("interim:lumberjack:setBuyer", function(data)
    createBuyerSpot(data)
end)

RegisterNetEvent("interim:lumberjack:clearBuyer", function()
    if buyerPed then
        DeleteEntity(buyerPed)
        buyerPed = nil
    end
    if sellBlip then
        RemoveBlip(sellBlip)
        sellBlip = nil
    end
end )





