--- @class Blips
local Blips <const> = {}

Blips.list = {}

--- @param blipData table
--- @return number|nil
function Blips.create(blipData)
    if not blipData or not blipData.position or not blipData.label then
        return nil
    end

    local position = blipData.position
    local blip = AddBlipForCoord(position.x, position.y, position.z)

    if not DoesBlipExist(blip) then
        return nil
    end

    SetBlipSprite(blip, blipData.sprite or 1)
    SetBlipColour(blip, blipData.color or 0)
    SetBlipScale(blip, (blipData.scale or 0.5) + 0.0)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipData.label)
    EndTextCommandSetBlipName(blip)

    return blip
end

--- @param blipId number
function Blips.remove(blipId)
    local blip <const> = Blips.list[blipId]

    if not blip then
        return
    end

    if blip then
        if DoesBlipExist(blip.blip) then
            RemoveBlip(blip.blip)
        end

        Blips.list[blipId] = nil
    end
end

function Blips.removeAll()
    for blipId, _ in pairs(Blips.list) do
        Blips.remove(blipId)
    end
end

--- @param blipId number
--- @param blipData table
function Blips.update(blipId, blipData)
    if not Blips.list[blipId] then
        return
    end

    local blip <const> = Blips.list[blipId].blip

    Blips.list[blipId] = blipData
    Blips.list[blipId].blip = blip

    if blipData.sprite then
        SetBlipSprite(blip, blipData.sprite)
    end

    if blipData.color then
        SetBlipColour(blip, blipData.color)
    end

    if blipData.scale then
        SetBlipScale(blip, blipData.scale + 0.0)
    end

    if blipData.label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(blipData.label)
        EndTextCommandSetBlipName(blip)
    end

    if blipData.position then
        SetBlipCoords(blip, blipData.position.x, blipData.position.y, blipData.position.z)
    end
end

function Blips.init()
    for blipId, blipData in pairs(Blips.list) do
        local blip <const> = Blips.create(blipData)

        if blip then
            Blips.list[blipId].blip = blip
        end
    end
end

RegisterNetEvent("blips:retrieve:list", function(blipsList)
    Blips.removeAll()
    Blips.list = blipsList
    Blips.init()
end)

RegisterNetEvent("blips:add:list", function(blipId, blipData)
    Blips.list[blipId] = blipData
    local blip <const> = Blips.create(blipData)

    if blip then
        Blips.list[blipId].blip = blip
    end
end)

RegisterNetEvent("blips:update:list", function(blipId, blipData)
    Blips.update(blipId, blipData)
end)

RegisterNetEvent("blips:remove:list", function(blipId)
    Blips.remove(blipId)
end)