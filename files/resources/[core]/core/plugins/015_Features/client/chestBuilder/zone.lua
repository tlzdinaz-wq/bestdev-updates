local chestFloatingShown = false
local chestFloatingId = nil

local function ShowChestFloating(id, worldPos, floatingZ)
    local onScreen, screenX, screenY = World3dToScreen2d(worldPos.x, worldPos.y, worldPos.z + (floatingZ or 0.5))
    if not onScreen then
        if chestFloatingShown then
            SendNUIMessage({ action = "floatingInteraction:hide" })
            chestFloatingShown = false
            chestFloatingId = nil
        end
        return
    end

    local data = {
        id = "chest_" .. tostring(id),
        title = "",
        screenX = screenX,
        screenY = screenY,
        buttons = {
            { label = "Ouvrir le coffre", key = "E" }
        }
    }

    if chestFloatingShown and chestFloatingId == id then
        SendNUIMessage({ action = "floatingInteraction:update", data = data })
    else
        SendNUIMessage({ action = "floatingInteraction:show", data = data })
        chestFloatingShown = true
        chestFloatingId = id
    end
end

local function HideChestFloating()
    if chestFloatingShown then
        SendNUIMessage({ action = "floatingInteraction:hide" })
        chestFloatingShown = false
        chestFloatingId = nil
    end
end

CreateThread(function()
    local sleep = 1000
    local chest
    local chestCoords
    local dist

    while true do
        sleep = 1000

        if IsNuiFocused() then
            HideChestFloating()
        else
            local found = false

            for i = 1, #ChestBuilder.cache do
                chest = ChestBuilder.cache[i]

                if not chest then
                    goto skip
                end

                if not ChestBuilder:PlayerCanSeeChest(chest) then
                    goto skip
                end

                chestCoords = vector3(chest.coords.x, chest.coords.y, chest.coords.z)
                dist = #(GetEntityCoords(PlayerPedId()) - chestCoords)

                if dist <= 2.0 then
                    found = true
                    sleep = 0
                    ShowChestFloating(chest.id, chestCoords, chest.coords and chest.coords.floatingZ)

                    if VFW.Interact.JustPressed(0, 38) then
                        HideChestFloating()
                        ChestBuilder:OpenChest(chest.id, chest.pincode)
                    end
                    break
                end

                ::skip::
            end

            if not found then
                HideChestFloating()
            end
        end

        Wait(sleep)
    end
end)
