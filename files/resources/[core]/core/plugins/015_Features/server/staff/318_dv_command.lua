-- /dv [rayon] : supprime le véhicule le plus proche, ou tous ceux du rayon donné (500 m au plus).
--
-- Appelée aussi par le bouton « Supprimer un véhicule » du menu staff (ExecuteCommand "dv 1" ou "dv <rayon>").
-- Sans rayon, ou avec un rayon d'1 m ou moins : le véhicule dans lequel on est, sinon le plus proche à moins de
-- 10 m. Avec un rayon plus grand : tous les véhicules du rayon. Les véhicules où un autre joueur est assis ne
-- sont jamais supprimés (le faire éjecterait le joueur en pleine conduite).

local MAX_RADIUS = 500.0
local NEAREST_RANGE = 10.0
local MAX_SEATS = 8

local function notify(source, variant, message)
    TriggerClientEvent("vfw:showNotification", source, {
        type = "STAFF",
        variant = variant,
        subtitle = "Véhicules",
        message = message,
        content = message,
    })
end

local function trimPlate(raw)
    if type(raw) ~= "string" then return "" end
    return (raw:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function distance(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

--- Un autre joueur que `except` est-il assis dans ce véhicule ?
local function occupiedByOther(vehicle, except)
    for seat = -1, MAX_SEATS - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 and ped ~= except and IsPedAPlayer(ped) then
            return true
        end
    end
    return false
end

--- Retire un véhicule du monde. S'il appartient à un joueur et qu'il était sorti, il part en fourrière : sinon il
--- resterait « sorti » en base sans exister, et son propriétaire ne pourrait plus le faire sortir.
---@return string plate
local function removeVehicle(vehicle)
    local plate = trimPlate(GetVehicleNumberPlateText(vehicle))

    if plate ~= "" then
        local api = VFW.Vehicles
        if type(api) == "table" and type(api.GetByPlate) == "function" then
            local row = api.GetByPlate(plate:upper()) or api.GetByPlate(plate)
            if row and not VFW.DB.IsSet(row.pounded) and not VFW.DB.IsSet(row.stored) then
                MySQL.update.await("UPDATE owned_vehicles SET pounded = 1, stored = 0 WHERE plate = ?", { row.plate })
            end
        end

        if MiscB and MiscB.ClearTempKeys then
            MiscB.ClearTempKeys(plate)
        end
    end

    DeleteEntity(vehicle)
    return plate
end

VFW.RegisterCommand("dv", "dv", function(source, xPlayer, args)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return end
    local origin = GetEntityCoords(ped)

    local radius = tonumber(args and args[1])
    if radius and (radius ~= radius or radius < 0) then
        notify(source, "ERROR", "Ce rayon n'est pas valide.")
        return
    end
    if radius and radius > MAX_RADIUS then radius = MAX_RADIUS end

    local targets = {}

    if not radius or radius <= 1.0 then
        local inside = GetVehiclePedIsIn(ped, false)
        if inside and inside ~= 0 and DoesEntityExist(inside) then
            targets[1] = inside
        else
            local best, bestDistance = nil, NEAREST_RANGE
            local all = GetAllVehicles() or {}
            for i = 1, #all do
                local vehicle = all[i]
                if DoesEntityExist(vehicle) then
                    local d = distance(origin, GetEntityCoords(vehicle))
                    if d <= bestDistance then best, bestDistance = vehicle, d end
                end
            end
            if best then targets[1] = best end
        end

        if #targets == 0 then
            notify(source, "ERROR", "Aucun véhicule à proximité.")
            return
        end
        if occupiedByOther(targets[1], ped) then
            notify(source, "ERROR", "Un joueur est dans ce véhicule.")
            return
        end
    else
        local all = GetAllVehicles() or {}
        for i = 1, #all do
            local vehicle = all[i]
            if DoesEntityExist(vehicle)
                and distance(origin, GetEntityCoords(vehicle)) <= radius
                and not occupiedByOther(vehicle, ped) then
                targets[#targets + 1] = vehicle
            end
        end

        if #targets == 0 then
            notify(source, "ERROR", ("Aucun véhicule à supprimer dans un rayon de %d m."):format(math.floor(radius)))
            return
        end
    end

    local plates = {}
    for i = 1, #targets do
        local plate = removeVehicle(targets[i])
        if #plates < 20 then plates[#plates + 1] = plate end
    end

    if #targets == 1 then
        local plate = plates[1]
        notify(source, "SUCCESS", plate ~= "" and ("Véhicule supprimé (plaque : %s)."):format(plate) or "Véhicule supprimé.")
    else
        notify(source, "SUCCESS", ("%d véhicules supprimés dans un rayon de %d m."):format(#targets, math.floor(radius)))
    end

    TriggerEvent("vfw:logs:staff", source, "vehicle_delete_radius", {
        radius = radius or 0,
        count = #targets,
        plates = plates,
    })
end, {
    help = "Supprimer le véhicule le plus proche, ou tous ceux dans un rayon",
    params = {
        { name = "rayon", help = "Rayon en mètres (500 au plus). Vide : le véhicule le plus proche" },
    },
})
