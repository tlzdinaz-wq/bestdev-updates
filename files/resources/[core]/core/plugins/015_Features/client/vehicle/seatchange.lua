---@diagnostic disable: undefined-global

local SEAT_MAP = {
    { index = 1, seat = -1 },
    { index = 2, seat = 0 },
    { index = 3, seat = 1 },
    { index = 4, seat = 2 },
    { index = 5, seat = 3 },
}

local isOpen = false

local function buildSeatData(vehicle, ped)
    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    local seats = {}
    for _, def in ipairs(SEAT_MAP) do
        local seatExists
        if def.seat == -1 then
            seatExists = maxSeats >= 1
        else
            seatExists = (def.seat + 1) < maxSeats
        end

        if seatExists then
            local occupant = GetPedInVehicleSeat(vehicle, def.seat)
            local status
            if occupant == ped then
                status = "self"
            elseif occupant ~= 0 and DoesEntityExist(occupant) then
                status = "occupied"
            else
                status = "free"
            end
            seats[#seats + 1] = {
                index = def.index,
                seat = def.seat,
                status = status,
            }
        end
    end
    return seats
end

local function closeMenu()
    if not isOpen then return end
    isOpen = false
    SendNUIMessage({ action = "nui:seatChange:close" })
    if VFW and VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(false)
    else
        SetNuiFocus(false, false)
    end
    if VFW and VFW.DisableEscapeMenu then
        VFW.DisableEscapeMenu(false)
    end
end

local function openMenu()
    if isOpen then return end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then return end

    local seats = buildSeatData(vehicle, ped)
    isOpen = true
    SendNUIMessage({
        action = "nui:seatChange:show",
        data = { seats = seats }
    })
    if VFW and VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(true, true)
    else
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    end
    if VFW and VFW.DisableEscapeMenu then
        VFW.DisableEscapeMenu(true)
    end
end

RegisterNUICallback("nui:seatChange:close", function(_, cb)
    closeMenu()
    cb({})
end)

RegisterNUICallback("nui:seatChange:select", function(data, cb)
    closeMenu()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then cb({}) return end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then cb({}) return end

    local targetSeat = tonumber(data and data.seat)
    if not targetSeat then cb({}) return end

    local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    if targetSeat == -1 then
        if maxSeats < 1 then cb({}) return end
    else
        if (targetSeat + 1) >= maxSeats then cb({}) return end
    end

    local occupant = GetPedInVehicleSeat(vehicle, targetSeat)
    if occupant == ped then cb({}) return end
    if occupant ~= 0 and DoesEntityExist(occupant) then
        if VFW and VFW.ShowNotification then
            VFW.ShowNotification({ type = "ROUGE", content = "Ce siège est déjà occupé." })
        end
        cb({}) return
    end

    SetPedIntoVehicle(ped, vehicle, targetSeat)
    cb({})
end)

local blockExitUntil = 0

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local inVeh = IsPedInAnyVehicle(ped, false)
        if inVeh then
            -- 21 = INPUT_SPRINT (LSHIFT), 23 = INPUT_ENTER (F, exit vehicle)
            -- 75 = INPUT_VEH_EXIT (also F by default)
            local shift = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)
            if shift or GetGameTimer() < blockExitUntil or isOpen then
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
            end
            if shift and not isOpen and IsDisabledControlJustPressed(0, 23) then
                blockExitUntil = GetGameTimer() + 800
                openMenu()
            end
        else
            Wait(250)
        end
    end
end)

AddEventHandler("vfw:exitedVehicle", function()
    if isOpen then closeMenu() end
end)
