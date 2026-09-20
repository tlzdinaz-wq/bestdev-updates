--- @class Society
Society = {}

Society.data = {
    service = false
}

RegisterNetEvent("core:retrieve:societyData", function(data)
    while not VFW?.PlayerData?.job do
        Wait(0)
    end

    Society.unload()
    Society.data = data
    -- Synchroniser avec l'état réel du service du joueur
    Society.data.service = VFW.PlayerData.job.onDuty or false
    Society.load()
end)

AddEventHandler("vfw:playerLoaded", function()
    TriggerServerEvent("core:society:requestData")
end)

function Society.unload()
    if Society.data and next(Society.data) then
        Society.unloadBlip()
        Society.unloadStorage()
        Society.unloadCustoms()
        Society.unloadDJ()
        Society.unloadCraft()
        Society.unloadManagement()
        Society.unloadCatalog()
        Society.unloadDoorbell()
    end
end

function Society.load()
    if Society.data and next(Society.data) then
        Society.initBlip()
        Society.initStorage()
        Society.initCustoms()
        Society.initDJ()
        Society.initCrafts()
        Society.initManagement()
        Society.initCatalog()
        Society.initDoorbell()
    end
end