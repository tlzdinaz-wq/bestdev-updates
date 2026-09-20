local currentBlip = nil

function Society.initBlip()
    if Society?.data?.blip?.enabled then
        local data <const> = Society.data.blip
        currentBlip = AddBlipForCoord(data.position.x, data.position.y, data.position.z)

        SetBlipSprite(currentBlip, data.sprite)
        SetBlipColour(currentBlip, data.color)
        SetBlipScale(currentBlip, data.scale)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(data.name)
        EndTextCommandSetBlipName(currentBlip)
    end
end

function Society.unloadBlip()
    if currentBlip then
        RemoveBlip(currentBlip)
        currentBlip = nil
    end
end