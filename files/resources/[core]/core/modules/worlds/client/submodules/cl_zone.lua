---@class Worlds.Zone
Worlds.Zone = {}

local points = {}
local duiPool = {}
local interactVisible = true
local screenWidth, screenHeight = GetActiveScreenResolution()
local POOL_SIZE = 25

local function GetDuiFromPool()

    for _, dui in pairs(duiPool) do
        if not dui.inUse then
            dui.inUse = true
            return dui
        end
    end

    if #duiPool < POOL_SIZE then
        local id = #duiPool + 1
        local duiObj = {
            id = id,
            object = CreateDui("nui://cfx-nui-core/modules/dui/index.html", screenWidth, screenHeight),
            handle = nil,
            duiTexture = "dui_texture_"..id,
            inUse = true
        }

        if duiObj.object then
            duiObj.handle = GetDuiHandle(duiObj.object)
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(duiObj.duiTexture), "duiImage", duiObj.handle)
            table.insert(duiPool, duiObj)
            return duiObj
        end

        Wait(50)
    end

    return nil
end

local function ReleaseDui(dui)
    if dui then
        dui.inUse = false
        SendDuiMessage(dui.object, json.encode({type = "reset"}))
    end
end

local activeRenders = {}

local function WorldLoop(handle, hauteur)
    if points[handle] and not points[handle].active then
        points[handle].active = true
        points[handle]._renderHauteur = hauteur or 0.45
        activeRenders[handle] = true
    end
end

-- Single centralized render thread for all zone DUI sprites
CreateThread(function()
    local colors = {255, 255, 255, 255}
    while true do
        local hasActive = false
        for handle in pairs(activeRenders) do
            if points[handle] and points[handle].active then
                hasActive = true
                if interactVisible and points[handle].dui then
                    local offset = points[handle]._renderHauteur or 0.45
                    local onScreen, screenX, screenY = World3dToScreen2d(points[handle].coords.x, points[handle].coords.y, points[handle].coords.z + offset)
                    if onScreen then
                        DrawSprite(points[handle].dui.duiTexture, "duiImage", screenX, screenY, 1.0, 1.0, 0.0, colors[1], colors[2], colors[3], colors[4])
                    end
                end
            else
                activeRenders[handle] = nil
            end
        end
        Wait(hasActive and 0 or 500)
    end
end)

---@param coords vector3
---@param distance number
---@param hidden boolean
---@param enter function
---@param leave function
---@param interactLabel string
---@param interactKey string
---@param interactIcons table
---@param color string|table
---@param hauteur number
---@return number
function Worlds.Zone.Create(coords, distance, hidden, enter, leave, interactLabel, interactKey, interactIcons, color, hauteur)
    local point = {
        coords = coords,
        distance = distance,
        hidden = hidden,
        enter = enter,
        leave = leave,
        interactLabel = interactLabel,
        interactKey = interactKey,
        interactIcons = interactIcons,
        color = color,
        hauteur = hauteur,
        dui = nil,
        active = false,
        nearby = false
    }
    local handle = #points + 1
    points[handle] = point
    return handle
end

---@param handle number
---@return void
function Worlds.Zone.Remove(handle)
    if not points[handle] then
        return
    end

    if points[handle].leave then
        points[handle].leave(handle)
    end

    if points[handle].dui then
        ReleaseDui(points[handle].dui)
        points[handle].dui = nil
    end

    activeRenders[handle] = nil
    points[handle] = nil
end

---@param handle number
---@return table
function Worlds.Zone.Get(handle)
    return points[handle]
end

---@param handle number
---@param hidden boolean
---@return void
function Worlds.Zone.Hide(handle, hidden)
    if points[handle] then
        points[handle].hidden = hidden
        if hidden and points[handle].dui then
            ReleaseDui(points[handle].dui)
            points[handle].dui = nil
            points[handle].active = false
            points[handle].nearby = false
            activeRenders[handle] = nil
        end
    end
end

---@param state boolean
---@return void
function Worlds.Zone.HideInteract(state)
    interactVisible = state
    for _, point in pairs(points) do
        if point.dui then
            SendDuiMessage(point.dui.object, json.encode({
                type = "setVisibility",
                data = {visible = state}
            }))
        end
    end
end

---@param handle number
---@param coords vector3
---@return void
function Worlds.Zone.UpdateCoords(handle, coords)
    if points[handle] then
        points[handle].coords = coords
    end
end

function Worlds.Zone.StartLoop()
    CreateThread(function()
        while true do
            local coords = GetEntityCoords(VFW.PlayerData.ped)
            local anyPlayerInZone = false

            for handle, point in pairs(points) do
                if not point.hidden then
                    if not type(point.coords) == "vector3" or not type(coords) == "vector3" then
                        assert("Invalid coordinates type for point: "..tostring(point.interactLabel))
                        return
                    end

                    local distanceToPlayer = #(vector3(coords.x, coords.y, coords.z) - vector3(point.coords.x, point.coords.y, point.coords.z))
                    if distanceToPlayer <= 7 then
                        if not point.dui then
                            point.dui = GetDuiFromPool()
                            if point.dui then
                                SendDuiMessage(points[handle].dui.object, json.encode({type = "setInteraction", data = {
                                    visible = false
                                }}))
                                SendDuiMessage(points[handle].dui.object, json.encode({type = "setPointVisibility", data = {
                                    visible = true,
                                    innerGradientStart = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[1],
                                    innerGradientEnd = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[2],
                                    outerStrokeStart = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[1],
                                    outerStrokeEnd = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[2],
                                    glowColor = "#FFFFFF"
                                }}))
                            end
                        end

                        if point.dui then
                            if distanceToPlayer <= 5 then
                                WorldLoop(handle, point.hauteur)

                                if distanceToPlayer <= point.distance then
                                    if not point.nearby then
                                        point.nearby = true
                                        anyPlayerInZone = true
                                        if point.enter then
                                            point.enter(handle)
                                        end

                                        SendDuiMessage(point.dui.object, json.encode({type = "setPointVisibility", data = {
                                            visible = false
                                        }}))
                                        
                                        SendDuiMessage(point.dui.object, json.encode({type = "setInteraction", data = {
                                            visible = true,
                                            key = point.interactKey,
                                            label = point.interactLabel,
                                            keyColor = not point.color and "#000000" or type(point.color) == "string" and "#FFFFFF" and #point.color> 2 and point.color[3] or "#FFFFFF",
                                            labelGradientStart = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[1],
                                            labelGradientEnd = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[2],
                                            labelOpacity = point.color and point.color[4] or 1.0,
                                            icons = point.interactIcons
                                        }}))
                                    end
                                elseif point.nearby then
                                    point.nearby = false
                                    if point.leave then
                                        point.leave(handle)
                                    end

                                    SendDuiMessage(points[handle].dui.object, json.encode({type = "setInteraction", data = {
                                        visible = false
                                    }}))
                                    SendDuiMessage(points[handle].dui.object, json.encode({type = "setPointVisibility", data = {
                                        visible = true,
                                        innerGradientStart = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[1],
                                        innerGradientEnd = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[2],
                                        outerStrokeStart = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[1],
                                        outerStrokeEnd = not point.color and "#FFFFFF" or type(point.color) == "string" and point.color or point.color[2],
                                        glowColor = "#FFFFFF"
                                    }}))
                                end
                            else
                                if point.nearby then
                                    point.nearby = false
                                    if point.leave then
                                        point.leave(handle)
                                    end

                                    SendDuiMessage(points[handle].dui.object, json.encode({type = "setInteraction", data = {
                                        visible = false
                                    }}))
                                end
                            end
                        end
                    elseif point.dui then
                        if point.leave then
                            point.leave(handle)
                        end

                        ReleaseDui(point.dui)
                        point.dui = nil
                        point.active = false
                        point.nearby = false
                    end
                end
            end

            Wait(anyPlayerInZone and 0 or 500)
        end
    end)
end