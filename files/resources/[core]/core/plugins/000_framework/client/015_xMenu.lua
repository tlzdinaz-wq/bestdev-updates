---@meta _
---@diagnostic disable: duplicate-doc-field

---@class xmenu
---@field cache table
---@field actualMenu boolean
---@field actualMenu boolean
xmenu = {}
xmenu.cache = {}
xmenu.actualMenu = false

--- .refresh
---@return any
function xmenu.refresh()
    if not xmenu.actualMenu then
        xmenu.state(false)
        return
    end

    local menuData = {
        id = xmenu.actualMenu.id,
        banner = xmenu.cache[xmenu.actualMenu.id].banner,
        theme = xmenu.cache[xmenu.actualMenu.id].theme,
        title = xmenu.cache[xmenu.actualMenu.id].title,
        subtitle = xmenu.cache[xmenu.actualMenu.id].subtitle,
        description = xmenu.cache[xmenu.actualMenu.id].description,
        item = xmenu.cache[xmenu.actualMenu.id].items,
        itemsPerPage = xmenu.cache[xmenu.actualMenu.id].itemsPerPage
    }

    if xmenu.cache[xmenu.actualMenu.id].isFirstRender then
        xmenu.state(true, menuData)
        xmenu.cache[xmenu.actualMenu.id].isFirstRender = false
    else
        xmenu.update(menuData)
    end
end

--- .render
---@param menu any
function xmenu.render(menu)
    xmenu.actualMenu = menu

    if menu then
        xmenu.cache[menu.id].isFirstRender = true
        xmenu.refresh()
    else
        xmenu.state(false)
    end
end

---uuid
function xmenu.uuid()
    local uuid = ''

    for ii = 0, 31 do
        if ii == 8 or ii == 20 then
            uuid = uuid .. '-'
            uuid = uuid .. string.format('%x', math.floor(math.random() * 16))
        elseif ii == 12 then
            uuid = uuid .. '-'
            uuid = uuid .. '4'
        elseif ii == 16 then
            uuid = uuid .. '-'
            uuid = uuid .. string.format('%x', math.floor(math.random() * 4) + 8)
        else
            uuid = uuid .. string.format('%x', math.floor(math.random() * 16))
        end
    end

    return uuid
end

---state
---@param state boolean
---@param data table
function xmenu.state(state, data)
    SendNUIMessage({
        action = 'nui:xmenu:visible',
        data = state
    })
    if data then
        SendNUIMessage({
            action = 'nui:xmenu:setData',
            data = data
        })
    end
end

---update
---@param data table
function xmenu.update(data)
    SendNUIMessage({
        action = 'nui:xmenu:setData',
        data = data
    })
end

---create
---@param style table
function xmenu.create(style)
    local id = xmenu.uuid()
    xmenu.cache[id] = {
        id = id,
        theme = "theme",
        banner = style.banner or false,
        title = style.title or "",
        subtitle = style.subtitle or "",
        description = style.description or "",
        itemsPerPage = style.itemsPerPage or 10,
        active = false,
    }
    RegisterNUICallback('onClose:'..id, function()
        if xmenu.cache[id].onClosed then
            xmenu.cache[id].onClosed()
        end
    end)
    return xmenu.cache[id]
end

---createSub
---@param parent table
---@param style table
function xmenu.createSub(parent, style)
    local id = xmenu.uuid()
    xmenu.cache[id] = {
        id = id,
        parent = parent,
        theme = parent.theme or "default",
        banner = style.banner or parent.banner,
        title = style.title or "",
        subtitle = style.subtitle or "",
        description = style.description or "",
        itemsPerPage = style.itemsPerPage or 10,
        active = false,
    }
    RegisterNUICallback('onClose:'..id, function()
        if xmenu.cache[id].onClosed then
            xmenu.cache[id].onClosed()
        end

        if xmenu.cache[id].parent then
            xmenu.render(xmenu.cache[id].parent)
        else
            xmenu.render(false)
        end
    end)
    return xmenu.cache[id]
end

---items
---@param menu table
---@param items function
function xmenu.items(menu, items)
    if xmenu.cache[menu.id].items ~= nil and #xmenu.cache[menu.id].items > 0 then
        for itemName, item in pairs(xmenu.cache[menu.id].items) do
            UnregisterRawNuiCallback('onSelected:' .. item.id)
            UnregisterRawNuiCallback('onHovered:' .. item.id)
            UnregisterRawNuiCallback('onActive:' .. item.id)
            UnregisterRawNuiCallback('onChange:' .. item.id)

            --UnregisterNUICallback
        end

        xmenu.cache[menu.id].items = {}
    else
        xmenu.cache[menu.id].items = {}
    end

    ---addButton
    ---@param label string
    ---@param style table
    ---@param action table
    ---@param submenu table
    function addButton(label, style, action, submenu)
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "button",
            id = id,
            label = label,
            style = style,
        })
        RegisterNUICallback("onSelected:"..id, function()
            return action and action.onSelected and action.onSelected()
        end)
        RegisterNUICallback("onSelected:"..id, function()
            if submenu then
                xmenu.render(submenu)
            end
        end)
        RegisterNUICallback("onHovered:"..id, function()
            return action and action.onHovered and action.onHovered()
        end)
        RegisterNUICallback("onActive:"..id, function()
            return action and action.onActive and action.onActive()
        end)
    end

    ---addSeparator
    ---@param label string
    function addSeparator(label)
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "separator",
            id = id,
            label = label,
        })
    end

    ---addLine
    function addLine()
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "line",
            id = id,
        })
    end

    ---addCheckbox
    ---@param label string
    ---@param state boolean
    ---@param style table
    ---@param action table
    function addCheckbox(label, state, style, action)
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "checkbox",
            id = id,
            default = state or false,
            label = label,
            style = style or {},
        })
        RegisterNUICallback("onChange:"..id, function(value)
            return action and action.onChange and action.onChange(value)
        end)
    end

    ---addSlider
    ---@param label string
    ---@param min number
    ---@param max number
    ---@param style table
    ---@param action table
    function addSlider(label, min, max, style, action)
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "slider",
            id = id,
            min = min or 0,
            max = max or 100,
            value = value or 0,
            style = style or {},
            label = label,
        })
        RegisterNUICallback("onChange:"..id, function(value)
            return action and action.onChange and action.onChange(value)
        end)
    end

    ---addList
    ---@param label string
    ---@param value Enum
    ---@param index number
    ---@param style table
    ---@param action table
    function addList(label, value, index, style, action)
        local id = xmenu.uuid()
        table.insert(xmenu.cache[menu.id].items, {
            type = "list",
            id = id,
            value = value or {},
            index = index or 1,
            style = style or {},
            label = label,
        })
        RegisterNUICallback("onSelected:"..id, function(value)
            return action and action.onSelected and action.onSelected(value)
        end)
        RegisterNUICallback("onChange:"..id, function(value)
            return action and action.onChange and action.onChange(value)
        end)
        RegisterNUICallback("onHovered:"..id, function()
            return action and action.onHovered and action.onHovered()
        end)
        RegisterNUICallback("onActive:"..id, function()
            return action and action.onActive and action.onActive()
        end)
    end

    ---onClose
    ---@param action function
    function onClose(action)
        xmenu.cache[menu.id].onClosed = action
    end

    items()

    if callback then
        callback(xmenu.cache)
    end
end

---Keybind
---@param key string
---@param command string
---@param name string
---@param callback function
local function Keybind(key, command, name, callback)
    Wait(150)
    RegisterCommand("+xmenu_" .. command, callback, false)
    RegisterKeyMapping("+xmenu_" .. command, name, "keyboard", key)
end

---KeybindToggle
---@param key string
---@param command string
---@param name string
---@param callback function
---@param callbackUnpressed function
local function KeybindToggle(key, command, name, callback, callbackUnpressed)
    RegisterCommand(('+xmenu_%s'):format(command), callback, false)
    RegisterCommand(('-xmenu_%s'):format(command), callbackUnpressed, false)
    RegisterKeyMapping(('~!+xmenu_%s'):format(command), name, 'keyboard', key)
end

local registered = {}
local lastPressTime = {}
local initialDelay = 200
local fastRepeat = 30

local REGISTERED_KEYS = {
    { key = 'up', desc = 'Menu Haut' },
    { key = 'down', desc = 'Menu Bas' },
    { key = 'left', desc = 'Menu Gauche' },
    { key = 'right', desc = 'Menu Droite' }
}

for i = 1, #REGISTERED_KEYS do
    registered[i] = false
    lastPressTime[i] = 0

    KeybindToggle(REGISTERED_KEYS[i].key, REGISTERED_KEYS[i].key, REGISTERED_KEYS[i].desc, function()
        if not xmenu.actualMenu then
            return
        end

        registered[i] = true
        local timer = 0
        local speed = initialDelay

        while registered[i] do
            local currentTime = GetGameTimer()

            if timer == 0 then
                SendNUIMessage({ action = ('nui:xmenu:%s'):format(REGISTERED_KEYS[i].key) })
                timer = 1
                lastPressTime[i] = currentTime
                Wait(speed)
            else
                if currentTime - lastPressTime[i] >= speed then
                    SendNUIMessage({ action = ('nui:xmenu:%s'):format(REGISTERED_KEYS[i].key) })
                    lastPressTime[i] = currentTime
                    speed = math.max(fastRepeat, speed - 15)
                end

                Wait(10)
            end
        end

    end, function()
        registered[i] = false
    end)
end

Keybind("return", "menu_click_item", "Menu Valider", function()
    if not xmenu.actualMenu then
        return
    end

    SendNUIMessage({ action = 'nui:xmenu:enter' })
end)

Keybind("back", "menu_return", "Menu Retour", function()
    if not xmenu.actualMenu then
        return
    end

    SendNUIMessage({ action = 'nui:xmenu:close' })
end)

Keybind("escape", "menu_back", "Quitter le menu", function()
    if not xmenu.actualMenu then
        return
    end

    SendNUIMessage({ action = 'nui:xmenu:close' })
end)

VFW.xMenu = xmenu
