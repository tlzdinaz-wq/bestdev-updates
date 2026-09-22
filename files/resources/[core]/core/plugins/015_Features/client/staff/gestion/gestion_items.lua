---@meta _
---@diagnostic disable: duplicate-doc-field

--- .SendItemGestionData
function VFW.SendItemGestionData()
    local itemsList = {}

    for itemName, item in pairs(VFW.Items) do
        if type(item) == "table" and item.type and item.type ~= "keys" and item.type ~= "clothes" then
            local itemData = type(item.data) == "table" and item.data or {}
            local typeI
            if item.data then
                if item.data.type == nil then
                    typeI = "objects"
              elseif item.data.type == "consumable" then
                    typeI = "consumable"
              elseif item.data.type == "drugs" then
                    typeI = "drugs"
              elseif string.find(itemName, "weapon_") then
                    typeI = "weapon"
              elseif item.data.type == "gpb" then
                    typeI = "gpb"
              elseif item.data.type == "ammo" then
                    typeI = "ammo"
              else
                    typeI = "objects"
              end
            else
                typeI = "objects"
          end

            itemsList[#itemsList + 1] = {
                name = itemName,
                label = item.label,
                type = typeI,
                weight = item.weight,
                image = item.image,
                premium = item.premium,
                permanent = item.perm,
                drop = itemData.drop,
                buyPrice = itemData.buyPrice,
                effect = itemData.effect,
                duration = itemData.duration,
                hunger = itemData.hunger,
                thirst = itemData.thirst,
                expiration = itemData.expiration,
                anim = itemData.anim,
                prop = itemData.prop,
                ammoType = itemData.ammoType
            }
        end
    end

    SendNUIMessage({
        action = "nui:server-gestion-items:items",
        data = itemsList
    })
end

local bypassDelete = {
    ["keys"] = true,
    ["outfit"] = true,
    ["hat"] = true,
    ["top"] = true,
    ["accessory"] = true,
    ["bottom"] = true,
    ["shoe"] = true
}
RegisterNuiCallback("nui:server-gestion-items:save", function(data)
    local changedItem = {}

    for i = 1, #data do
        local item = data[i]
        local typeI
        if item.type == "weapon" then
            typeI = "weapons"
      elseif item.type == "objects" or item.type == "gpb" or item.type == "ammo" or item.type == "drugs" or item.type == "consumable" or item.type == "component" or item.type == "tint" then
            typeI = "items"
      else
            typeI = item.type
        end

        if not VFW.Items[item.name] then
            changedItem[item.name] = {
                label = item.label,
                type = typeI,
                weight = item.weight,
                image = item.image,
                premium = item.premium or false,
                perm = item.permanent or false,
                data = {
                    drop = item.drop,
                    type = item.type,
                    buyPrice = item.buyPrice,
                    effect = item.effect,
                    duration = item.duration,
                    hunger = item.hunger,
                    thirst = item.thirst,
                    expiration = item.expiration,
                    anim = item.anim,
                    prop = item.prop,
                    ammoType = item.ammoType
                }
            }
            VFW.Items[item.name] = changedItem[item.name]
        else
            local editItem = {
                label = item.label,
                type = typeI,
                weight = item.weight,
                image = item.image,
                premium = item.premium,
                perm = item.permanent,
                data = {
                    drop = item.drop,
                    type = item.type,
                    buyPrice = item.buyPrice,
                    effect = item.effect,
                    duration = item.duration,
                    hunger = item.hunger,
                    thirst = item.thirst,
                    expiration = item.expiration,
                    anim = item.anim,
                    prop = item.prop,
                    ammoType = item.ammoType
                }
            }
            local change = false

            for itemName, itemV in pairs(VFW.Items[item.name]) do
                if (itemName == "data") then
                    for e, j in pairs(itemV) do
                        if editItem[itemName][e] ~= j then
                            change = true
                            break
                        end
                    end

                    if change then
                        break
                    end
                elseif editItem[itemName] ~= itemV then
                    change = true
                    break
                end
            end

            if not change then
                for itemName, itemValue in pairs(editItem) do
                    if (itemName == "data") then
                        for e, j in pairs(itemValue) do
                            if VFW.Items[item.name][itemName][e] ~= j then
                                change = true
                                break
                            end
                        end

                        if change then
                            break
                        end
                    elseif VFW.Items[item.name][itemName] ~= itemValue then
                        change = true
                        break
                    end
                end
            end

            if change then
                changedItem[item.name] = editItem
                VFW.Items[item.name] = editItem
            end
        end
    end

    for itemName, item in pairs(VFW.Items) do
        if not bypassDelete[itemName] then
            local found = false

            for i = 1, #data do
                if data[i].name == itemName then
                    found = true
                    break
                end
            end

            if not found then
                changedItem[itemName] = "delete"
              VFW.Items[itemName] = nil
            end
        end
    end

    console.debug(json.encode(changedItem, {indent = true}))

    TriggerServerEvent("vfw:staff:saveItems", changedItem)
end)

RegisterNUICallback("nui:server-gestion-items:give", function(data)
    ExecuteCommand(("giveitem me %s %s"):format(data, 1))
end)
