---@meta _
---@diagnostic disable: duplicate-doc-field

local blips = {}

--- Create a blip at the specified coordinates
---@param coords vector3
---@param sprite number
---@param color number
---@param scale number
---@param name string
---@return Blip
function VFW.CreateBlipInternal(coords, sprite, color, scale, name)
    local coords = vector3(coords?.pos?.x or coords.x, coords?.pos?.y or coords.y, coords?.pos?.z or coords.z)

    local self = AddBlipForCoord(coords)
    SetBlipSprite(self, sprite)
    SetBlipDisplay(self, 4)
    SetBlipScale(self, scale)
    SetBlipColour(self, color)
    SetBlipAsShortRange(self, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(self)

    blips[self] = {
        id = #blips + 1,
        blip = self,
        coords = coords,
        sprite = sprite,
        color = color,
        scale = scale,
        name = name
    }

    return self
end

--- Create a blip with radius at the specified coordinates
---@param coords vector3
---@param radius number
---@param sprite number
---@param color number
---@param scale number
---@param name string
---@param alpha? number Optional alpha value (0-255), defaults to 100
---@param radiusColor? number Optional radius color, defaults to same as blip color
---@param radiusAlpha? number Optional radius alpha (0-255), defaults to 50
---@return table {blip: Blip, radiusBlip: Blip}
function VFW.CreateBlipRadius(coords, radius, sprite, color, scale, name, radiusAlpha, radiusColor)
    radiusColor = radiusColor or color
    radiusAlpha = radiusAlpha or 100
    
    local mainBlip <const> = AddBlipForCoord(coords.pos or coords)
    SetBlipSprite(mainBlip, sprite)
    SetBlipDisplay(mainBlip, 4)
    SetBlipScale(mainBlip, scale)
    SetBlipColour(mainBlip, color)
    SetBlipAsShortRange(mainBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(mainBlip)
    
    local radiusBlip <const> = AddBlipForRadius(coords.pos or coords, radius)
    SetBlipSprite(radiusBlip, 1)
    SetBlipColour(radiusBlip, radiusColor)
    SetBlipAlpha(radiusBlip, radiusAlpha)
    
    local blipData = {
        id = #blips + 1,
        blip = mainBlip,
        radiusBlip = radiusBlip,
        coords = coords,
        radius = radius,
        sprite = sprite,
        color = color,
        scale = scale,
        name = name,
        alpha = alpha,
        radiusColor = radiusColor,
        radiusAlpha = radiusAlpha,
        isRadiusBlip = true
    }
    
    blips[mainBlip] = blipData
    
    return {
        blip = mainBlip,
        radiusBlip = radiusBlip
    }
end

--- Get or create a blip group
---@return table
function VFW.GetBlipGroups()
    local groups = {}

    for _, blip in pairs(blips) do
        local key = string.format("%d_%d_%f_%s", blip.sprite, blip.color, blip.scale, blip.name)
        if not groups[key] then
            groups[key] = {
                sprite = blip.sprite,
                color = blip.color,
                scale = blip.scale,
                name = blip.name,
                ---@class coords
                coords = {}
            }
        end

        table.insert(groups[key].coords, blip.coords)
    end

    return groups
end

--- Remove a blip by its handle
---@param handle string
function VFW.RemoveBlipInternal(handle)
    if blips[handle] then
        RemoveBlip(blips[handle].blip)
        if blips[handle].radiusBlip then
            RemoveBlip(blips[handle].radiusBlip)
        end
        blips[handle] = nil
    end
end

--- Update the coordinates of a blip
---@param handle string
---@param coords vector3
function VFW.UpdateBlipInternal(handle, coords)
    if blips[handle] then
        SetBlipCoords(blips[handle].blip, coords.x, coords.y, coords.z)
        if blips[handle].radiusBlip then
            SetBlipCoords(blips[handle].radiusBlip, coords.x, coords.y, coords.z)
        end
        blips[handle].coords = coords
    end
end

--- Get all blips
---@return table<string, Blip>
function VFW.GetAllBlips() return blips end

RegisterNUICallback("nui:blips:goto", function(data)
    console.debug("nui:blips:goto", json.encode(data))
    SetEntityCoords(PlayerPedId(), data.x, data.y, data.z)
    VFW.ShowNotification("Vous avez été téléporté à la position du blip. "..data.label or "Sans nom")
end)

RegisterNUICallback("nui:blips:create", function(data)
    TriggerServerEvent("vfw:blips:create", data)
end)

RegisterNuiCallback("nui:blips:getPos", function()
    local pos = GetEntityCoords(PlayerPedId())
    console.debug("nui:blips:getPos", json.encode(pos))
    SendNUIMessage({
        action = "nui:blips:getPos",
        data = pos
    })
end)

---@param data table
RegisterNetEvent("vfw:blips:create", function(data)
    VFW.CreateBlipInternal({pos = vector3(data.positions.x, data.positions.y, data.positions.z), label = "Custom"}, data.sprite, data.couleur, data.taille, data.nom)
end)

RegisterNuiCallback("nui:blips:close", function(data)
    VFW.Nui.BlipsBuilder(false)
    VFW.Nui.Focus(false)
end)