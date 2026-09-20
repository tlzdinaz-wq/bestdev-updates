---@meta _
---@diagnostic disable: duplicate-doc-field

local Hospitals = {}
local HospitalBlips = {}

local function CleanupHospital(id)
    if HospitalBlips[id] and DoesBlipExist(HospitalBlips[id]) then
        RemoveBlip(HospitalBlips[id])
        HospitalBlips[id] = nil
    end
end

local function SetupHospital(id, hospital)
    if not hospital.pos then
        return
    end

    if hospital.active then
        if hospital.blipEnabled then
            if not HospitalBlips[id] or not DoesBlipExist(HospitalBlips[id]) then
                local blip = AddBlipForCoord(hospital.pos.x, hospital.pos.y, hospital.pos.z)

                SetBlipSprite(blip, 61)
                SetBlipScale(blip, 0.5)
                SetBlipColour(blip, 18)
                SetBlipAsShortRange(blip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(hospital.name)
                EndTextCommandSetBlipName(blip)

                HospitalBlips[id] = blip
            end
        else
            if HospitalBlips[id] and DoesBlipExist(HospitalBlips[id]) then
                RemoveBlip(HospitalBlips[id])
                HospitalBlips[id] = nil
            end
        end
    else
        CleanupHospital(id)
    end
end

RegisterNetEvent("sn_sams:hospital:sync")
AddEventHandler("sn_sams:hospital:sync", function(hospitals)
    for id, _ in pairs(HospitalBlips) do
        if not hospitals[id] then
            CleanupHospital(id)
        end
    end

    Hospitals = hospitals

    for id, hospital in pairs(hospitals) do
        SetupHospital(id, hospital)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, _ in pairs(HospitalBlips) do
            CleanupHospital(id)
        end
    end
end)
