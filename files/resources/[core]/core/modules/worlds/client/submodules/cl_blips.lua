---@class Worlds.Blips
Worlds.Blips = {}
local blips = {}

---@param coords vector3
---@param sprite number
---@param color number
---@param scale number
---@param name string
---@return Blip
function Worlds.Blips.Create(coords, sprite, color, scale, name)
    local self = AddBlipForCoord(coords.x, coords.y, coords.z)
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

---@return table
function Worlds.Blips.GetGroups()
    local groups = {}

    for _, blip in pairs(blips) do
        local key = string.format("%d_%d_%f_%s", blip.sprite, blip.color, blip.scale, blip.name)
        if not groups[key] then
            groups[key] = {
                sprite = blip.sprite,
                color = blip.color,
                scale = blip.scale,
                name = blip.name,
                coords = {}
            }
        end

        table.insert(groups[key].coords, blip.coords)
    end

    return groups
end

---@param handle string
function Worlds.Blips.Remove(handle)
    if blips[handle] then
        RemoveBlip(blips[handle].blip)
        blips[handle] = nil
    end
end

---@param handle string
---@param coords vector3
function Worlds.Blips.Update(handle, coords)
    if blips[handle] then
        SetBlipCoords(blips[handle].blip, coords.x, coords.y, coords.z)
        blips[handle].coords = coords
    end
end

---@return table<string, Blip>
function Worlds.Blips.GetAll() return blips end

RegisterNUICallback("nui:blips:goto", function(data)
    SetEntityCoords(PlayerPedId(), data.x, data.y, data.z)
    VFW.ShowNotification("Vous avez été téléporté à la position du blip. "..data.label or "Sans nom")
end)

RegisterNUICallback("nui:blips:create", function(data)
    TriggerServerEvent("vfw:blips:create", data)
end)

RegisterNuiCallback("nui:blips:getPos", function()
    local pos = GetEntityCoords(PlayerPedId())
    SendNUIMessage({
        action = "nui:blips:getPos",
        data = pos
    })
end)

---@param data table
RegisterNetEvent("vfw:blips:create", function(data)
    Worlds.Blips.Create({pos = vector3(data.positions.x, data.positions.y, data.positions.z), label = "Custom"}, data.sprite, data.couleur, data.taille, data.nom)
end)

RegisterNuiCallback("nui:blips:close", function(data)
    VFW.Nui.BlipsBuilder(false)
    VFW.Nui.Focus(false)
end)