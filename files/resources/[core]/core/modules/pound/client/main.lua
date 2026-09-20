--- @class Pound
local Pound <const> = {}

Pound.blip = {
    sprite = 477,
    color = 21,
    scale = 0.5,
    title = "Fourrière",
}

Pound.currentPound = nil
Pound.vehicle = nil
Pound.list = {}

local function getVehiclePerformanceStats(modelName)
    local hash <const> = GetHashKey(modelName)

    local maxSpeed <const> = GetVehicleModelMaxSpeed(hash)
    local acceleration <const> = GetVehicleModelAcceleration(hash)
    local maxBraking <const> = GetVehicleModelMaxBraking(hash)
    local maxTraction <const> = GetVehicleModelMaxTraction(hash)

    local speedPct <const> = math.min(100, math.floor((maxSpeed / 80.0) * 100))
    local accelPct <const> = math.min(100, math.floor((acceleration / 0.45) * 100))
    local brakePct <const> = math.min(100, math.floor((maxBraking / 3.5) * 100))
    local tractPct <const> = math.min(100, math.floor((maxTraction / 3.0) * 100))

    return speedPct, accelPct, brakePct, tractPct
end

function Pound.open()
    VFW.Nui.Focus(true, false)

    local result <const> = TriggerServerCallback("garage:getAllPoundedPlayerVehicles", Pound.currentPound.id)
    if not result then
        VFW.Nui.Focus(false, false)
        Pound.currentPound = nil
        VFW.ShowNotification({ type = 'ROUGE', content = "Impossible de charger les véhicules en fourrière." })
        return
    end
    local privateVehicles = result.vehicles or {}
    local price = result.price or 500

    for _, veh in ipairs(privateVehicles) do
        local speed, accel, braking, traction = getVehiclePerformanceStats(veh.name)
        veh.speed = speed
        veh.acceleration = accel
        veh.braking = braking
        veh.traction = traction
    end

    SendNUIMessage({
        action = "nui:pound:open",
        data = {
            vehicles = privateVehicles,
            price = price,
            location = Pound.currentPound.label or "Fourriere",
        }
    })
end

function Pound.close()
    VFW.Nui.Focus(false, false)
    Pound.currentPound = nil
end

--- @param id number
function Pound.remove(id)
    if Pound.list[id] then
        local pound = Pound.list[id]

        if pound.entity then
            DeleteEntity(pound.entity)
            pound.entity = nil
        end

        if pound.blip then
            RemoveBlip(pound.blip)
        end

        Pound.list[id] = nil
    end
end

local function createBlip(id, position)
    local blip <const> = AddBlipForCoord(position.x, position.y, position.z)

    SetBlipSprite(blip, Pound.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Pound.blip.scale)
    SetBlipColour(blip, Pound.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Pound.blip.title)
    EndTextCommandSetBlipName(blip)

    return blip
end

local function createPed(model, x, y, z, w)
    if not IsModelInCdimage(model) then return nil end

    VFW.Streaming.RequestModel(model)

    local ped <const> = CreatePed(4, model, x, y, z, w or 231.13241, false, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(ped) then return nil end

    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStandStill(ped, -1)
    SetPedCanBeTargetted(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanPlayAmbientAnims(ped, false)
    SetPedCanPlayGestureAnims(ped, false)

    return ped
end

--- @param id number
--- @param pound table
function Pound.create(id, pound)
    Pound.list[id] = pound

    local pos <const> = pound.position
    local blip <const> = createBlip(id, pos)

    Pound.list[id].blip = blip
end

function Pound.removeAll()
    for index, _ in pairs(Pound.list) do
        Pound.remove(index)
    end
end

function Pound.init()
    for index, _ in pairs(Pound.list) do
        local pos <const> = Pound.list[index].position
        local blip <const> = createBlip(index, pos)

        Pound.list[index].blip = blip
    end
end

RegisterNetEvent("pound:load", function(list)
    Pound.list = list
    Pound.init()
end)

RegisterNetEvent("pound:update", function(id, pound)
    Pound.remove(id)
    Pound.create(id, pound)
end)

RegisterNetEvent("pound:delete", function(id)
    Pound.remove(id)
end)

RegisterNetEvent("pound:create", function(id, pound)
    Pound.create(id, pound)
end)

AddEventHandler("pound:close", function()
    Pound.close()
end)

RegisterNUICallback("nui:pound:close", function(_, cb)
    Pound.close()
    cb({ ok = true })
end)

RegisterNUICallback("pound:takeOutVehicle", function(data, cb)
    local paymentMethod = data.paymentMethod or "bank"
    if Pound.currentPound then
        TriggerServerEvent("pound:restoreVehicle", data.vehicle.plate, Pound.currentPound.id, paymentMethod)
    end
    Pound.close()
    cb({ ok = true })
end)

CreateThread(function()
    while true do
        local timer = 1100
        local ped <const> = PlayerPedId()
        local pos <const> = GetEntityCoords(ped)

        for index, data in pairs(Pound.list) do
            local dist <const> = #(vector3(pos.x, pos.y, pos.z) - vector3(data.position.x, data.position.y, data.position.z))

            if data.useMarker then
                if dist < 15 then
                    timer = 0
                    local time <const> = GetGameTimer() / 1000.0
                    local bobZ <const> = math.sin(time * 0.4) * 0.05
                    local rotZ <const> = (time * 30.0) % 360.0
                    DrawMarker(36, data.position.x, data.position.y, data.position.z + 0.3 + bobZ, 0.0, 0.0, 0.0, 0.0, 0.0, rotZ, 0.8, 0.8, 0.8, 0, 100, 255, 200, true, false, 2, true, nil, false)
                end
            else
                if data.entity and not DoesEntityExist(data.entity) then
                    data.entity = nil
                end

                if dist < 100 and not data.entity then
                    data.entity = createPed(GetHashKey(data.pedModel or "a_m_y_business_02"), data.position.x, data.position.y, data.position.z, data.position.w or 231.13241)
                end

                if dist > 100 and data.entity then
                    DeleteEntity(data.entity)
                    data.entity = nil
                end
            end

            if dist < 2 and not Pound.currentPound then
                timer = 0
                VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour accéder à la fourrière.")

                if VFW.Interact.JustReleased(0, 51) then
                    Pound.currentPound = data
                    Pound.open()
                end
            end
        end

        Wait(timer)
    end
end)
