local _stretcherModels = {}
if SN_SAMS and SN_SAMS.Config and SN_SAMS.Config.Stretcher then
    for _, hash in ipairs(SN_SAMS.Config.Stretcher.modelHashes) do
        _stretcherModels[GetHashKey(hash)] = true
    end
end

VFW.ContextAddButton("vehicle", " Fermer / Ouvrir le véhicule", function(vehicle)
    return DoesEntityExist(vehicle) and not _stretcherModels[GetEntityModel(vehicle)] and not IsPedInAnyVehicle(VFW.PlayerData.ped, false)
end, function(vehicle)
    TriggerServerEvent("vfw:vehicle:open")
end, {}, nil)
