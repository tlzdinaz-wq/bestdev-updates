---@meta _
---@diagnostic disable: duplicate-doc-field

local interacts = {}
local duis = {}
local interactVisible = true

---Create DuiObject
---@param url any
---@param width number|string
---@param height any
---@return number|table|boolean Created object or success status
local function CreateDuiObject(url, width, height)
    local id = #duis + 1
    duis[id] = {
        id = id,
        object = nil,
        handle = nil,
        duiTexture = tostring(id)
    }
    duis[id].object = CreateDui(url, width, height)
    if not duis[id].object then
        console.debug("Erreur lors de la création du DUI")
        return
    end

    duis[id].handle = GetDuiHandle(duis[id].object)
    CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(duis[id].duiTexture), "duiImage", duis[id].handle)
    return duis[id]
end

--- WorldLoop
---@param handle any
---@param pos vector3|table Position
local function WorldLoop(handle, pos)
    local colors = { 255, 255, 255, 255 }
    CreateThread(function()
        if interacts[handle] and not interacts[handle].active then
            interacts[handle].active = true
            while (interacts[handle] and interacts[handle].active) do
                if interactVisible then
                    local onScreen, screenX, screenY = World3dToScreen2d(pos.x, pos.y, pos.z + 0.45)
                    if (interacts[handle] and interacts[handle].dui and onScreen) then
                        DrawSprite(interacts[handle].dui.duiTexture, "duiImage", screenX, screenY, 1.0, 1.0, 0.0, colors[1], colors[2], colors[3], colors[4])
                    end
                end

                Wait(1)
            end
        end
    end)
end

--- .HideInteract
---@param state any
function VFW.HideInteract(state)
    interactVisible = not state
end

--- .DestroyInteract
---@param key any
function VFW.DestroyInteract(key)
    if interacts[key] then
        interacts[key] = nil
    end
end

---Create VFW.Interact
---@param key any
---@param pos vector3|table Position
function VFW.CreateInteract(key, pos)
    if not interacts[key] then
        interacts[key] = {
            active = false,
            dui = nil
        }
    end

    if type(pos) ~= "vector3" then
        pos = vector3(pos.x, pos.y, pos.z)
    end

    if not pos.x or not pos.y or not pos.z then
        console.debug("Invalid position for interact " .. key)
        return
    end

    if not interacts[key].dui then
        console.debug("Creating DUI for point ".. key.. ("at position %s"):format(pos))
        local x, y = GetActualScreenResolution()
        interacts[key].dui = CreateDuiObject("nui://cfx-nui-core/modules/dui/index.html", x, y)
    end

    WorldLoop(key, pos)
end

--- .SendDataInteract
---@param key any
---@param _data table
---@return any
function VFW.SendDataInteract(key, _data)
    if not interacts[key] then
        return
    end

    SendDuiMessage(interacts[key].dui.object, json.encode({ type = _data.type, data = {
        visible = _data.visible,
        innerGradientStart = _data.innerGradientStart or "#FFFFFF",
        innerGradientEnd = _data.innerGradientEnd or "#FFFFFF",
        outerStrokeStart = _data.outerStrokeStart or "#FFFFFF",
        outerStrokeEnd = _data.outerStrokeEnd or "#FFFFFF",
        glowColor = _data.glowColor or "#FFFFFF",
        key = _data.interactKey,
        label = _data.interactLabel,
        keyColor = _data.keyColor,
        labelGradientStart = _data.labelGradientStart or "#FFFFFF",
        labelGradientEnd = _data.labelGradientEnd or "#FFFFFF",
        labelOpacity = _data.labelOpacity or 1.0,
        icons = _data.interactIcons
    } }))
end