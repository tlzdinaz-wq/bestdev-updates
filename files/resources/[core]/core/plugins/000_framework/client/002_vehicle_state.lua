---@meta _
---@diagnostic disable: duplicate-doc-field

-- Vehicule courant du joueur et siege occupe, tenus a jour dans VFW.PlayerData.
--
-- Cinq modules lisaient `VFW.PlayerData.vehicle` et `VFW.PlayerData.seat` — sirenes et
-- gyrophares, HUD, animations, outils staff, customs — mais personne ne les ecrivait, hors
-- un cas isole dans le menu customs. `seat` valait donc toujours nil.
--
-- Pour les sirenes c'etait fatal : leur garde demande `seat == -1`, c'est-a-dire etre au
-- volant. `nil ~= -1` etant vrai, la garde refusait tout le monde, tout le temps. Ni les
-- sirenes ni les gyrophares n'ont jamais pu fonctionner pour personne.

local POLL_ON_FOOT <const> = 350
local POLL_IN_VEHICLE <const> = 700

--- Siege occupe par ce ped, -1 pour le conducteur.
---
--- Il n'existe pas de native rendant directement le siege : on parcourt les places, du
--- conducteur au dernier passager.
local function seatOf(vehicle, ped)
    if GetPedInVehicleSeat(vehicle, -1) == ped then return -1 end

    for seat = 0, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then return seat end
    end

    return nil
end

CreateThread(function()
    while true do
        local wait = POLL_ON_FOOT

        if type(VFW) == "table" and type(VFW.PlayerData) == "table" then
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)

            if vehicle ~= 0 and DoesEntityExist(vehicle) then
                VFW.PlayerData.vehicle = vehicle
                VFW.PlayerData.seat = seatOf(vehicle, ped)
                wait = POLL_IN_VEHICLE
            elseif VFW.PlayerData.vehicle ~= nil or VFW.PlayerData.seat ~= nil then
                VFW.PlayerData.vehicle = nil
                VFW.PlayerData.seat = nil
            end
        end

        Wait(wait)
    end
end)
