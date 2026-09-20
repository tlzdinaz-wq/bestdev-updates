local activeBlips = {}
local function CreatePoliceBlip(blipData)
    if not blipData.position then return false end

    local blip = AddBlipForCoord(blipData.position.x, blipData.position.y, blipData.position.z)

    SetBlipSprite(blip, blipData.sprite or 161)
    SetBlipColour(blip, blipData.color or 1)
    SetBlipScale(blip, blipData.scale or 0.5)
    SetBlipAsShortRange(blip, false)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.label or "Zone d'intérêt")
    EndTextCommandSetBlipName(blip)

    local duration = (blipData.duration or 5) * 60 * 1000
    local blipId = #activeBlips + 1
    activeBlips[blipId] = {
        blip = blip,
        expiresAt = GetGameTimer() + duration
    }

    SetTimeout(duration, function()
        if activeBlips[blipId] and DoesBlipExist(activeBlips[blipId].blip) then
            RemoveBlip(activeBlips[blipId].blip)
            activeBlips[blipId] = nil
        end
    end)

    return true
end
RegisterNetEvent("core:legal:createPoliceBlip")
AddEventHandler("core:legal:createPoliceBlip", function(blipData)
    CreatePoliceBlip(blipData)
end)

RegisterNetEvent("core:legal:removeAllBlips")
AddEventHandler("core:legal:removeAllBlips", function()
    for id, blipInfo in pairs(activeBlips) do
        if DoesBlipExist(blipInfo.blip) then
            RemoveBlip(blipInfo.blip)
        end
        activeBlips[id] = nil
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local currentTime = GetGameTimer()
        for id, blipInfo in pairs(activeBlips) do
            if blipInfo.expiresAt and currentTime > blipInfo.expiresAt then
                if DoesBlipExist(blipInfo.blip) then
                    RemoveBlip(blipInfo.blip)
                end
                activeBlips[id] = nil
            end
        end
    end
end)
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for id, blipInfo in pairs(activeBlips) do
            if DoesBlipExist(blipInfo.blip) then
                RemoveBlip(blipInfo.blip)
            end
        end
        activeBlips = {}
    end
end)