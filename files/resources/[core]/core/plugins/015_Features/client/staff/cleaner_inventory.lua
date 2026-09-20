---@meta _
---@diagnostic disable: duplicate-doc-field

--- .InventoryCleaner
---@param playerId number|table Player ID or player object
---@param name string
---@return any
function VFW.InventoryCleaner(playerId, name)
    if VFW.StateInventory() then
        return
    end

    local inventory = TriggerServerCallback("vfw:staff:getInventory", playerId) or {}
    local uiItems = {}

    for i, v in ipairs(inventory) do
        local def = VFW.Items[v.name]

        if def then
            uiItems[#uiItems + 1] = {
                id = i,
                name = v.name,
                count = v.count,
                label = def.label or v.name,
                url = VFW.ItemImageUrl(v.name, def),
                weight = def.weight,
                type = def.type,
                premium = v.premium,
                position = v.position,
                metadatas = v.meta
            }
        end
    end

    VFW.Nui.Focus(true, false)
    SetCursorLocation(0.5, 0.5)

    SendNUIMessage({
        action = "nui:inventorycleaner:open",
        data = {
            inventory = uiItems,
            fullname = name,
            source = playerId
        }
    })
end

RegisterNUICallback("nui:inventorycleaner:close", function(_, cb)
    if not VFW.PlayerGlobalData.permissions["inventaire"] then
        return
    end

    VFW.Nui.Focus(false, false)
    cb("ok")
end)

RegisterNUICallback("nui:inventorycleaner:deleteItems", function(data, cb)
    if not VFW.PlayerGlobalData.permissions["inventaire"] then
        return
    end

    TriggerServerEvent("vfw:staff:deteleItems", data.source, data.items)
    VFW.Nui.Focus(false, false)
    cb("ok")
end)
