local VUI <const> = exports["VUI"]

local DRAW_DIST <const> = 15.0
local INTERACT_DIST <const> = 2.0
local NEAR_VEHICLE_DIST <const> = 5.0
local VEHICLE_PLATE_MAX <const> = 8

local MARKER_SIZE <const> = vector3(1.5, 1.5, 0.5)
local MARKER_COLOR <const> = { r = 200, g = 30, b = 30, a = 120 }

local menuOpen = false

local function getTargetVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and DoesEntityExist(veh) then return veh end

    local coords = GetEntityCoords(ped)
    local nearest, nearestDist = 0, 9999.0
    local vehPool = GetGamePool("CVehicle")
    for i = 1, #vehPool do
        local v = vehPool[i]
        if DoesEntityExist(v) then
            local d = #(GetEntityCoords(v) - coords)
            if d < nearestDist then
                nearestDist = d
                nearest = v
            end
        end
    end
    if nearest ~= 0 and nearestDist <= NEAR_VEHICLE_DIST then return nearest end
    return nil
end

local function applyPlateOnEntity(veh, newPlate)
    if not DoesEntityExist(veh) then return end
    if not NetworkHasControlOfEntity(veh) then
        NetworkRequestControlOfEntity(veh)
        local waited = 0
        while not NetworkHasControlOfEntity(veh) and waited < 1000 do
            Wait(50); waited = waited + 50
        end
    end
    SetVehicleNumberPlateText(veh, newPlate)
end

local function notify(variant, content)
    local color = (variant == "error" and "ROUGE") or (variant == "warning" and "ORANGE") or "VERT"
    VFW.ShowNotification({ type = color, content = content })
end

local function requestPlateChange(point, veh, useRandom, manualPlate)
    local oldPlate = GetVehicleNumberPlateText(veh)
    if not oldPlate or oldPlate == "" then
        return notify("error", "Impossible de lire la plaque du véhicule.")
    end

    local result = TriggerServerCallback("garageIllegal:changePlate",
        point.id, manualPlate, oldPlate, useRandom and true or false)

    if not result or not result.success then
        return notify("error", (result and result.message) or "Erreur.")
    end

    applyPlateOnEntity(veh, result.newPlate)

    if result.charged and result.charged > 0 then
        notify("success", ("Plaque changée : %s → %s (-%s sale)"):format(oldPlate, result.newPlate, VFW.Math.FormatMoney(result.charged)))
    else
        notify("success", ("Plaque changée : %s → %s"):format(oldPlate, result.newPlate))
    end
end

local function openPlateMenu(point)
    if menuOpen then return end

    local veh = getTargetVehicle()
    if not veh then
        return notify("error", "Aucun véhicule proche ou dans lequel vous êtes.")
    end

    local banner = exports["core"]:GetVUIBanner("faction")
    local menu = VUI:CreateMenu(point.name or "Garage Illégal", banner, true)

    menuOpen = true
    menu.OnOpen(function()
        menu.ClearItems()

        local plate = GetVehicleNumberPlateText(veh) or "?"
        local costLabel
        if point.isPaid and point.price > 0 then
            costLabel = (VFW.Math.FormatMoney(point.price) .. " sale")
        else
            costLabel = "Gratuit"
        end

        menu.Button("Plaque actuelle", nil, plate, nil, false, function() end)
        menu.Button("Coût", nil, costLabel, nil, false, function() end)
        menu.Separator()

        if point.plateMode == "random" or point.plateMode == "both" then
            menu.Button("Plaque aléatoire", "Générer une plaque aléatoire unique.", nil, "chevron", false, function()
                menu.close()
                requestPlateChange(point, veh, true, nil)
            end)
        end

        if point.plateMode == "manual" or point.plateMode == "both" then
            menu.Button("Plaque manuelle", "Saisir une plaque (1 à 8 caractères).", nil, "chevron", false, function()
                local input = VFW.Nui.KeyboardInput(true, "Entrez la nouvelle plaque")
                if not input or input == "" then return end
                if #input > VEHICLE_PLATE_MAX then
                    return notify("error", "La plaque doit faire 8 caractères maximum.")
                end
                menu.close()
                requestPlateChange(point, veh, false, input)
            end)
        end
    end)

    menu.OnClose(function()
        menuOpen = false
    end)

    menu.open()
end

CreateThread(function()
    while true do
        local sleep = 1000

        if not menuOpen and not IsNuiFocused() then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local closestPoint, closestDist = nil, 9999.0

            for i = 1, #GarageIllegal.points do
                local p = GarageIllegal.points[i]
                if GarageIllegal:CanUse(p) then
                    local d = #(coords - vector3(p.coords.x, p.coords.y, p.coords.z))

                    if d <= DRAW_DIST then
                        sleep = 0
                        DrawMarker(
                            1,
                            p.coords.x, p.coords.y, p.coords.z - 0.03,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            MARKER_SIZE.x, MARKER_SIZE.y, MARKER_SIZE.z,
                            MARKER_COLOR.r, MARKER_COLOR.g, MARKER_COLOR.b, MARKER_COLOR.a,
                            false, false, 2, false, nil, nil, false
                        )
                    end

                    if d < closestDist then
                        closestDist = d
                        closestPoint = p
                    end
                end
            end

            if closestPoint and closestDist <= INTERACT_DIST then
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour changer la plaque")
                if VFW.Interact.JustPressed(0, 38) then
                    openPlateMenu(closestPoint)
                end
            end
        end

        Wait(sleep)
    end
end)
