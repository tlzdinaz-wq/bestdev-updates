-- Paid Shop - Animaux (Peds) Client-Side
-- Transformation du joueur en l'animal acheté (catégorie "peds" de la boutique F1).
-- Possession permanente : la liste vient de owned_peds (server). La transformation
-- est validée serveur (paidshop:verifyPedOwnership) puis exécutée client (SetPlayerModel).
--
-- Le pattern de model-swap reprend exactement core:client:setped / core:client:unsetped
-- (freeze + invincibilité pendant le swap pour éviter le crash réseau, garde IsPedHuman
-- sur les peds animaux qui n'ont pas de composants humanoïdes).

---@diagnostic disable: undefined-global

local isMorphedAsPed = false

-- Effectue le model-swap vers un modèle ped donné. Renvoie true si le swap a réussi.
local function applyPedModel(model)
    if type(model) ~= "string" or model == "" then return false end

    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false
    end

    RequestModel(hash)
    local loadWait = 0
    while not HasModelLoaded(hash) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(hash) then
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), hash)

    local newPed = PlayerPedId()
    local timeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and timeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        timeout = timeout + 1
    end

    -- SetPedDefaultComponentVariation assume un ped humanoïde : on l'évite sur les animaux.
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(hash)

    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
    end

    if newPed and newPed ~= 0 then
        SetEntityHealth(newPed, GetEntityMaxHealth(newPed))
    end

    if VFW and VFW.SetPlayerData then
        VFW.SetPlayerData("ped", PlayerPedId())
    end

    return true
end

-- Récupère la liste des animaux possédés (onglet "Mes Animaux")
RegisterNUICallback('paidshop:getOwnedPeds', function(data, cb)
    local peds = TriggerServerCallback('paidshop:getOwnedPeds')
    cb(peds or {})
end)

-- Transformation en l'animal acheté
RegisterNUICallback('paidshop:morphIntoPed', function(data, cb)
    local pedModel = data and data.pedModel
    if type(pedModel) ~= "string" or pedModel == "" then
        cb({ success = false, message = "Ce modèle d'animal n'est pas valide" })
        return
    end

    -- Anti-triche : on vérifie la possession côté serveur avant le swap.
    local owns = TriggerServerCallback('paidshop:verifyPedOwnership', pedModel)
    if not owns then
        cb({ success = false, message = "Vous ne possédez pas cet animal" })
        return
    end

    local ok = applyPedModel(pedModel)
    if ok then
        isMorphedAsPed = true
        cb({ success = true })
    else
        cb({ success = false, message = "Impossible de charger le modèle de l'animal" })
    end
end)

-- Retour à l'apparence humaine : on remet le bon modèle freemode/custom puis on
-- ré-applique le skin sauvegardé serveur (même logique que core:client:unsetped).
RegisterNUICallback('paidshop:revertToHuman', function(data, cb)
    local skin = TriggerServerCallback("vfw:skin:getPlayerSkin")
    if not skin then
        cb({ success = false, message = "Skin introuvable" })
        return
    end

    local ped = "mp_m_freemode_01"
    if skin.sex == 1 then
        ped = "mp_f_freemode_01"
    elseif skin.sex and skin.sex > 1 and Config and Config.PedsCharCreator then
        ped = Config.PedsCharCreator[skin.sex - 1] or ped
    end

    if not IsModelInCdimage(ped) or not IsModelValid(ped) then
        cb({ success = false, message = "Ce modèle humain n'est pas valide" })
        return
    end

    RequestModel(ped)
    local loadWait = 0
    while not HasModelLoaded(ped) and loadWait < 5000 do
        Wait(50)
        loadWait = loadWait + 50
    end
    if not HasModelLoaded(ped) then
        SetModelAsNoLongerNeeded(ped)
        cb({ success = false, message = "Le modèle humain n'a pas pu être chargé à temps" })
        return
    end

    local oldPed = PlayerPedId()
    FreezeEntityPosition(oldPed, true)
    SetEntityInvincible(oldPed, true)

    SetPlayerModel(PlayerId(), ped)
    local newPed = PlayerPedId()
    local timeout = 0
    while (not newPed or newPed == 0 or not DoesEntityExist(newPed)) and timeout < 30 do
        Wait(50)
        newPed = PlayerPedId()
        timeout = timeout + 1
    end
    if newPed and newPed ~= 0 and IsPedHuman(newPed) then
        SetPedDefaultComponentVariation(newPed)
    end
    SetModelAsNoLongerNeeded(ped)

    Wait(500)
    if newPed and newPed ~= 0 then
        FreezeEntityPosition(newPed, false)
        SetEntityInvincible(newPed, false)
    end

    TriggerEvent('skinchanger:loadSkin', skin or {})

    if VFW and VFW.SetPlayerData then
        VFW.SetPlayerData("ped", PlayerPedId())
    end

    isMorphedAsPed = false
    cb({ success = true })
end)
