---@meta _
---@diagnostic disable: duplicate-doc-field

-- Sirenes et gyrophares : initialisation de l'etat du vehicule.
--
-- Le client demande au serveur de preparer l'etat d'un vehicule d'urgence des qu'il s'y
-- installe, puis attend que `stateEnsured` soit vrai avant d'autoriser quoi que ce soit :
-- gyrophares, klaxon, sirene, changement de son — les quatre touches commencent par
-- verifier ce drapeau.
--
-- L'evenement n'avait jamais eu de destinataire. `stateEnsured` restait donc nil pour
-- toujours, et aucune des quatre touches ne faisait quoi que ce soit, pour personne.
-- Le client le redemandait toutes les 100 ms, sans reponse.
--
-- Cote client : plugins/015_Features/client/vehicle/siren.lua

RegisterNetEvent("Renewed-Sirensync:server:SyncState", function(netId)
    local source = source
    local id = tonumber(netId)
    if not id then return end

    local vehicle = NetworkGetEntityFromNetworkId(id)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    -- Le demandeur doit etre dans ce vehicule : sans ce controle, n'importe qui pourrait
    -- reinitialiser l'etat du vehicule d'un autre et lui couper sa sirene.
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 or GetVehiclePedIsIn(ped, false) ~= vehicle then return end

    local state = Entity(vehicle).state
    if state.stateEnsured then return end

    -- Valeurs de depart, repliquees : les trois clefs que lit le client, plus le drapeau
    -- qui lui dit que le vehicule est pret.
    state:set("lightsOn", false, true)
    state:set("horn", false, true)
    state:set("sirenMode", 0, true)
    state:set("stateEnsured", true, true)
end)
