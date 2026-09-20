---@meta _
---@diagnostic disable: duplicate-doc-field

local open = false
local vehicle = nil
local cams = nil

--- .OpenPound
---@param data table
function VFW.OpenPound(data)
    open = not open
    VFW.Nui.Focus(open, open)
    VFW.Nui.HudVisible(not open)
    SendNUIMessage({
        action = "nui:pound:visible",
        data = open
    })
    if open then
        SetCursorLocation(0.5, 0.5)
        cams = data
        SetEntityVisible(VFW.PlayerData.ped, false)
        VFW.Cam:Create("pound", cams.Preview.Cam)

        local dataPound = TriggerServerCallback("vfw:getPound")
        local spawned = false

        for k, v in pairs(dataPound) do
            for i = 1, #v do
                if not spawned then
                    spawned = true
                    local vehicleHash = VFW.Streaming.RequestModel(v[i].model)
                    local pos = cams.Preview.Vehicle
                    vehicle = CreateVehicle(vehicleHash, pos.x, pos.y, pos.z, pos.w, false, false)
                    SetModelAsNoLongerNeeded(vehicleHash)
                    FreezeEntityPosition(vehicle, true)
                    SetEntityCollision(vehicle, true, true)
                    VFW.Game.SetVehicleProperties(vehicle, v[i].prop)
                end

                v[i].prop = nil
                v[i].name = GetDisplayNameFromVehicleModel(joaat(v[i].model))
                v[i].label = Garage.GetVehicleLabel(v[i].model)
            end
        end

        SendNUIMessage({
            action = "nui:pound:data",
            data = dataPound
        })

        local pools = {
            "CPed",
            "CObject",
            "CNetObject",
            "CPickup",
            "CVehicle"
        }
        while open do
            for i = 1, #pools do
                local pool = GetGamePool('CVehicle')

                for i = 1, #pool do
                    SetEntityLocallyInvisible(pool[i])
                end
            end

            Wait(0)
        end
    else
        if vehicle then
            DeleteEntity(vehicle)
            vehicle = nil
        end

        VFW.Cam:Destroy("pound")
        SetEntityVisible(VFW.PlayerData.ped, true)
    end
end

RegisterNuiCallback("nui:pound:close", function()
    if not open then
        return
    end

    VFW.OpenPound(cams)
end)

RegisterNuiCallback("nui:pound:use", function(data)
    if not open then
        return
    end

    TriggerServerEvent("vfw:pound:use", cams.Pos, data.id, GetMakeNameFromVehicleModel(data.model))
    VFW.OpenPound(cams)
end)

RegisterNUICallback("nui:pound:selectedItem", function(data)
    if not open then
        return
    end

    if vehicle then
        DeleteEntity(vehicle)
        vehicle = nil
    end

    local model, prop = TriggerServerCallback("vfw:garagePublic:get", data.id)
    if not model then
        return
    end

    local vehicleHash = VFW.Streaming.RequestModel(model)
    console.debug("Model : ", model)
    console.debug("Vehicle Hash : ", vehicleHash)

    console.debug("Camera : ", json.encode(cams.Preview, {indent = true}))
    local pos = cams.Preview.Vehicle
    console.debug("pos : ", json.encode(pos, {indent = true}))
    vehicle = CreateVehicle(vehicleHash, pos.x, pos.y, pos.z, pos.w, false, false)
    console.debug("Vehicle : ", vehicle)
    SetModelAsNoLongerNeeded(vehicleHash)
    FreezeEntityPosition(vehicle, true)
    SetEntityCollision(vehicle, true, true)
    VFW.Game.SetVehicleProperties(vehicle, prop)
end)