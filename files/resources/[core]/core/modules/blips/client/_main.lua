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
    local x, y, z = tonumber(position.x), tonumber(position.y), tonumber(position.z)
    if not x or not y or not z then
        return nil
    end

    local blip = AddBlipForCoord(x + 0.0, y + 0.0, z + 0.0)

    if not DoesBlipExist(blip) then
        return nil
    end

    SetBlipSprite(blip, math.floor(tonumber(blipData.sprite) or 1))
    SetBlipDisplay(blip, 4)
    SetBlipColour(blip, math.floor(tonumber(blipData.color) or 0))
    SetBlipScale(blip, (tonumber(blipData.scale) or 0.8) + 0.0)
    -- Courte portee : sur la minimap un blip n'apparait qu'a proximite. En longue portee, il reste colle au
    -- bord de la minimap meme a l'autre bout de la map.
    SetBlipAsShortRange(blip, true)
    SetBlipHighDetail(blip, true)
    SetBlipPriority(blip, 10)

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
    blipId = tostring(blipId)
    if Blips.list[blipId] and Blips.list[blipId].blip then
        Blips.remove(blipId)
    end
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

CreateThread(function()
    Wait(2500)
    TriggerServerEvent("blips:request:list")
end)