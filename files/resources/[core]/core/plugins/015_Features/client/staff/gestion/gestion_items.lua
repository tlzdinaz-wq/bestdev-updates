---@meta _
---@diagnostic disable: duplicate-doc-field

--- .SendItemGestionData
function VFW.SendItemGestionData()
    local itemsList = {}

    for itemName, item in pairs(VFW.Items or {}) do
        if type(item) == "table" and item.type ~= "keys" and item.type ~= "clothes" then
            local itemData = type(item.data) == "table" and item.data or {}
            local typeI
            if type(item.data) == "table" then
                if itemData.type == nil then
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
RegisterNuiCallback("nui:server-gestion-items:save", function(data, cb)
    if type(data) ~= "table" or #data == 0 then
        if cb then cb({ ok = false, error = "Liste vide : aucune modification appliquee." }) end
        return
    end
    for i = 1, #data do
        if type(data[i]) ~= "table" or type(data[i].name) ~= "string" or data[i].name == "" then
            if cb then cb({ ok = false, error = "Liste d'items invalide." }) end
            return
        end
    end
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
            end
        end
    end

    -- Une liste filtree/paginee n'est jamais une demande de suppression.
    -- Seules les modifications explicites partent aux endpoints serveur controles.
    for name, edit in pairs(changedItem) do
        edit.data.image = edit.image
        if VFW.Items[name] then
            TriggerServerEvent("vfw:staff:saveItem", name, edit)
        else
            TriggerServerEvent("vfw:staff:createItem", name, edit.label, edit.weight, edit.data, edit.premium, edit.perm)
        end
    end
    if cb then cb({ ok = true, queued = true }) end
end)

RegisterNUICallback("nui:server-gestion-items:give", function(data)
    ExecuteCommand(("giveitem me %s %s"):format(data, 1))
end)
