---@meta _

-- Empêche le démarrage des véhicules sortis des garages de job (restricted_garage)
-- si le conducteur n'appartient pas au job propriétaire du véhicule.
-- Le state bag "JobRestricted" est posé au spawn dans modules/garage/server/restricted_garage.lua.

local notifiedVehicle = nil

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
            local restrictedJob = Entity(vehicle).state.JobRestricted
            if restrictedJob and restrictedJob ~= "" then
                local playerJob = VFW.PlayerData and VFW.PlayerData.job
                local playerJobName = playerJob and playerJob.name or nil
                local playerSocietyType = Society and Society.data and Society.data.type or nil

                if playerJobName ~= restrictedJob and playerSocietyType ~= "mechanic" then
                    sleep = 0
                    SetVehicleEngineOn(vehicle, false, true, true)

                    if notifiedVehicle ~= vehicle then
                        notifiedVehicle = vehicle
                        VFW.ShowNotification({
                            type = "ROUGE",
                            content = "Ce véhicule appartient à un service, vous n'avez pas les clés."
                        })
                    end
                elseif notifiedVehicle == vehicle then
                    notifiedVehicle = nil
                end
            end
        elseif notifiedVehicle then
            notifiedVehicle = nil
        end

        Wait(sleep)
    end
end)
