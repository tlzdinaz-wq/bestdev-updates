---@meta _
---@diagnostic disable: duplicate-doc-field

-- ════════════════════════════════════════════════
-- Ciseau client — sélection cible, application de la coupe
-- ════════════════════════════════════════════════

local CISEAU = {
    maxDistance = 3.0,
}

local isCutting = false

--- Tente de couper les cheveux du ped cible.
--- Vérifie distance + mains levées sur la cible avant de lancer l'anim.
---@param targetPed number
---@return boolean
local function TryCutHair(targetPed)
    if isCutting then return false end
    if not targetPed or not DoesEntityExist(targetPed) or not IsPedAPlayer(targetPed) then
        VFW.ShowNotification({ type = "ROUGE", content = "Cette cible n'est pas valide." })
        return false
    end

    local myPed = PlayerPedId()
    if targetPed == myPed then
        VFW.ShowNotification({ type = "ROUGE", content = "Tu ne peux pas te couper les cheveux toi-même." })
        return false
    end

    if #(GetEntityCoords(myPed) - GetEntityCoords(targetPed)) > CISEAU.maxDistance then
        VFW.ShowNotification({ type = "ROUGE", content = "Vous êtes trop loin." })
        return false
    end

    if not VFW.IsPlayerHandsUp(targetPed) then
        VFW.ShowNotification({ type = "ROUGE", content = "Cette personne doit avoir les mains levées." })
        return false
    end

    local targetPlayer = NetworkGetPlayerIndexFromPed(targetPed)
    local targetServerId = targetPlayer ~= -1 and GetPlayerServerId(targetPlayer) or 0
    if not targetServerId or targetServerId == 0 then
        VFW.ShowNotification({ type = "ROUGE", content = "Joueur introuvable." })
        return false
    end

    isCutting = true
    TriggerServerEvent("ciseau:requestCut", targetServerId)
    isCutting = false

    VFW.ShowNotification({ type = "VERT", content = "Coupe effectuée." })
    return true
end

VFW.UseCiseau = TryCutHair

-- Mode inventaire : ouvre un sélecteur de joueur dans le rayon
RegisterNetEvent("core:UseCiseau", function()
    VFW.CloseInventory()

    if isCutting then return end

    local myPed = PlayerPedId()
    if IsPedInAnyVehicle(myPed, false) then
        VFW.ShowNotification({ type = "ROUGE", content = "Impossible en véhicule." })
        return
    end

    local targetPlayerId = VFW.StartSelect(CISEAU.maxDistance + 0.5, true)
    if not targetPlayerId then
        VFW.ShowNotification({ type = "ORANGE", content = "Aucune cible sélectionnée." })
        return
    end

    local targetPed = GetPlayerPed(targetPlayerId)
    TryCutHair(targetPed)
end)

-- Reception sur la cible : appliquer la coupe rasée et persister le skin
RegisterNetEvent("ciseau:applyHaircut", function(cutterServerId)
    local ped = PlayerPedId()

    SetPedComponentVariation(ped, 2, 0, 0, 2)

    TriggerEvent("skinchanger:getSkin", function(skin)
        if skin then
            skin.hair_1 = 0
            skin.hair_2 = 0
            TriggerServerEvent("vfw:skin:save", skin)
            TriggerEvent("skinchanger:loadSkin", skin)
        end
    end)

    VFW.ShowNotification({ type = "ORANGE", content = "Quelqu'un t'a coupé les cheveux..." })
end)
