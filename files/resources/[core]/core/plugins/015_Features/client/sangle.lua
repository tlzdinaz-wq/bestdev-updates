---@meta _
---@diagnostic disable: duplicate-doc-field

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/default.png")
local main = VUI:CreateMenu("Action disponible", defaultBanner, true)
local attach = VUI:CreateSubMenu(main, "Action disponible", defaultBanner, true)

local ATTACH_OFFSET = 2

local inChoice = false
local firstVeh = nil
local secondVeh = nil
local deleteVeh = nil

local offsets = { posX = 0.0, posY = 0.0, posZ = 0.0, rotX = 0.0, rotY = 0.0, rotZ = 0.0 }
local offsetOrder = { "posX", "posY", "posZ", "rotX", "rotY", "rotZ" }
local offsetPrompt = {
    posX = "Choisir la position X",
    posY = "Choisir la position Y",
    posZ = "Choisir la position Z",
    rotX = "Choisir la rotation X",
    rotY = "Choisir la rotation Y",
    rotZ = "Choisir la rotation Z"
}
local offsetButtons = {}
local offsetByIndex = {}
local currentOffset = nil

local function ResetState()
    for _, key in ipairs(offsetOrder) do
        offsets[key] = 0.0
    end

    firstVeh = nil
    secondVeh = nil
    deleteVeh = nil
end

local function OffsetLabel(key)
    return key .. ": " .. string.format("%.2f", offsets[key])
end

local function RefreshOffset(key)
    local button = offsetButtons[key]

    if button and button.Update then
        button.Update({ title = OffsetLabel(key) })
    end
end

---Get Vehicles
---@return number|nil Vehicle handle
local function GetVehicles()
    local vehicles = {}

    for vehicle in EnumerateVehicles() do
        table.insert(vehicles, vehicle)
    end

    return vehicles
end

---Get AllVehicleInArea
---@param coords vector3|table Coordinates
---@param zone any
---@return number|nil Vehicle handle
local function GetAllVehicleInArea(coords, zone)
    local vehiclesInArea = {}

    if zone == nil then
        zone = 150.0
    end

    for _, vehicle in pairs(GetVehicles()) do
        local pCoords = GetEntityCoords(vehicle)

        if #(vector3(pCoords.x, pCoords.y, pCoords.z) - vector3(coords.x, coords.y, coords.z)) <= zone then
            table.insert(vehiclesInArea, vehicle)
        end
    end

    return vehiclesInArea
end

local function SelectVehicle(veh, prompt)
    VFW.ShowNotification({
        type = 'VERT',
        duration = 10,
        content = "Appuyer sur ~K E pour valider"
    })

    VFW.ShowNotification({
        type = 'JAUNE',
        duration = 10,
        content = prompt
    })

    VFW.ShowNotification({
        type = 'ROUGE',
        duration = 10,
        content = "Appuyez sur ~K X pour annuler"
    })

    local timer = GetGameTimer() + 10000

    while inChoice do
        if next(veh) then
            SetEntityAlpha(veh[1], 50, false)

            local mCoors = GetEntityCoords(veh[1])

            DrawMarker(20, mCoors.x, mCoors.y, mCoors.z + 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 255, 255, 255, 120, 0, 1, 2, 0, nil, nil, 0)

            if GetGameTimer() > timer then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Le délai est dépassé"
                })

                ResetEntityAlpha(veh[1])

                inChoice = false
                return nil
            elseif VFW.Interact.JustPressed(0, 51) then
                local selected = veh[1]

                inChoice = false

                ResetEntityAlpha(selected)
                return selected
            elseif IsControlJustPressed(0, 182) then
                ResetEntityAlpha(veh[1])

                table.remove(veh, 1)

                if next(veh) then
                    timer = GetGameTimer() + 10000
                end
            elseif IsControlJustPressed(0, 73) then
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = "Vous avez annulé"
                })

                ResetEntityAlpha(veh[1])

                inChoice = false
                return nil
            end
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Il n'y a aucun véhicule autour de vous"
            })

            inChoice = false
            return nil
        end

        Wait(0)
    end

    return nil
end

local function BuildMain()
    main.Button("Detacher un véhicule", nil, ">", "chevron", false, function()
        local attached = {}
        local veh = GetAllVehicleInArea(GetEntityCoords(VFW.PlayerData.ped), 10.0)

        for _, value in pairs(veh) do
            if GetEntityAttachedTo(value) ~= 0 then
                table.insert(attached, value)
            end
        end

        inChoice = true
        deleteVeh = SelectVehicle(attached, "Appuyer sur ~K L pour choisir le véhicule à détacher")

        if not deleteVeh then
            return
        end

        DetachEntity(deleteVeh, true, true)
    end)

    main.Button("Attacher deux véhicules", nil, ">", "chevron", false, function()
        inChoice = true

        local veh = GetAllVehicleInArea(GetEntityCoords(VFW.PlayerData.ped), 10.0)
        firstVeh = SelectVehicle(veh, "Appuyer sur ~K L pour choisir le premier véhicule")

        if not firstVeh then
            return false
        end

        veh = GetAllVehicleInArea(GetEntityCoords(VFW.PlayerData.ped), 10.0)

        for k, v in pairs(veh) do
            if v == firstVeh then
                table.remove(veh, k)
            end
        end

        inChoice = true
        Wait(300)

        secondVeh = SelectVehicle(veh, "Appuyer sur ~K L pour choisir le second véhicule")

        if not secondVeh then
            return false
        end
    end, attach)
end

local function BuildAttach()
    offsetButtons = {}
    offsetByIndex = {}
    currentOffset = nil

    attach.Button("Valider", nil, nil, "chevron", false, function()
        exports['VUI']:CloseAll()
    end)

    attach.Button("Detacher/Annuler", nil, nil, "chevron", false, function()
        if firstVeh and DoesEntityExist(firstVeh) then
            DetachEntity(firstVeh, true, true)
        end

        if secondVeh and DoesEntityExist(secondVeh) then
            DetachEntity(secondVeh, true, true)
        end
    end)

    local position = ATTACH_OFFSET

    for _, key in ipairs(offsetOrder) do
        position = position + 1
        offsetByIndex[position] = key

        offsetButtons[key] = attach.Button(OffsetLabel(key), nil, nil, "chevron", false, function()
            local input = VFW.Nui.KeyboardInput(true, offsetPrompt[key], string.format("%.2f", offsets[key]))
            local value = tonumber(input)

            if not value then
                return
            end

            offsets[key] = value + 0.0
            RefreshOffset(key)
        end)
    end
end

main.OnOpen(function()
    BuildMain()
end)

attach.OnIndexChange(function(index)
    currentOffset = offsetByIndex[index]
end)

attach.OnOpen(function()
    BuildAttach()

    CreateThread(function()
        local pending = nil
        local pushedAt = 0

        while attach.opened do
            if firstVeh and secondVeh and DoesEntityExist(firstVeh) and DoesEntityExist(secondVeh) then
                AttachEntityToEntity(secondVeh, firstVeh, GetEntityBoneIndexByName(firstVeh, "platelight"),
                    offsets.posX, offsets.posY, offsets.posZ,
                    offsets.rotX, offsets.rotY, offsets.rotZ,
                    false, false, false, false, 0.0, true)
            end

            if currentOffset then
                if IsControlPressed(0, 174) then
                    offsets[currentOffset] = offsets[currentOffset] - 0.01
                    pending = currentOffset
                elseif IsControlPressed(0, 175) then
                    offsets[currentOffset] = offsets[currentOffset] + 0.01
                    pending = currentOffset
                end
            end

            if pending and GetGameTimer() - pushedAt >= 50 then
                RefreshOffset(pending)
                pushedAt = GetGameTimer()
                pending = nil
            end

            Wait(0)
        end

        if pending then
            RefreshOffset(pending)
        end
    end)
end)

local function OpenPositionCar()
    if not main.opened then
        ResetState()
    end

    main.toggle()
end

RegisterNetEvent("core:UseSangle")
AddEventHandler("core:UseSangle", function()
    OpenPositionCar()
end)
