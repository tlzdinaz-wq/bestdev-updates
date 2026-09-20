---@meta _
---@diagnostic disable: duplicate-doc-field

---Create VFW.BlipAndPoint
---@param name string
---@param positions vector3|table Position
---@param key any
---@param blipSprite any
---@param blipColor any
---@param blipScale any
---@param blipLabel string
---@param interactLabel string
---@param interactKey any
---@param interactIcons any
---@param action any
---@param colors any
function VFW.CreateBlipAndPoint(name, positions, key, blipSprite, blipColor, blipScale, blipLabel, interactLabel, interactKey, interactIcons, action, colors)
    if blipSprite then
        VFW.CreateBlipInternal(positions, blipSprite, blipColor, blipScale, blipLabel)
    end

    console.debug("Creating point "..name.." "..key)

    local handler = Worlds.Zone.Create(positions, 3, false, function()
        console.debug("Entering interaction zone "..name.." "..key)
        if action.onEnter then
            action.onEnter()
        end

        if action.onPress then
            VFW.RegisterInteraction(name .. key, action.onPress)
        end

    end, function()
        console.debug("Exiting interaction zone "..name.." "..key)
        VFW.RemoveInteraction(name .. key)
        if action.onExit then
            action.onExit()
        end

    end, interactLabel, interactKey, interactIcons, colors)

    return handler
end