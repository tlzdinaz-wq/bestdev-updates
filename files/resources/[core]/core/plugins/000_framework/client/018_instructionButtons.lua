---@meta _
---@diagnostic disable: duplicate-doc-field

---Create VariableWatcher
---@param table any
---@param callback function Callback function
---@return number|table|boolean Created object or success status
function createVariableWatcher(table, callback)
    local proxy = {}
    local mt = {
        __index = table,
        __newindex = function(t, key, value)
            local oldValue = table[key]

            table[key] = value

            if json.encode(oldValue) ~= json.encode(value) then
                callback(key, oldValue, value)
            end
        end
    }

    setmetatable(proxy, mt)

    return proxy
end

--- generateUniqueID
---@param length any
function generateUniqueID(length)
    local chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local length = tonumber(length) or 6
    local id = ''

    for i = 1, length do
        local randomIndex = math.random(#chars)

        id = id .. chars:sub(randomIndex, randomIndex)
    end

    return id
end

local parametersButtons = {
    hide = false
}

local activeThread = nil
local currentScaleform = nil

local controlKeyMap = {
    [1] = "Souris", [14] = "↕", [15] = "↕",
    [16] = "↓", [17] = "↑",
    [20] = "W", [21] = "SHIFT", [22] = "ESPACE", [23] = "F",
    [24] = "Clic G", [25] = "Clic D", [29] = "B",
    [32] = "Z", [33] = "S", [34] = "Q", [35] = "D", [36] = "CTRL",
    [38] = "E", [44] = "A", [45] = "R", [47] = "G",
    [51] = "E", [73] = "X", [74] = "F",
    [105] = "H",
    [172] = "↑", [173] = "↓", [174] = "←", [175] = "→", [179] = "ESPACE",
    [177] = "ESC", [191] = "ENTRÉE", [194] = "⌫", [200] = "ESC",
    [201] = "ENTRÉE", [202] = "⌫",
    [237] = "↑", [238] = "↓",
    [241] = "Molette", [242] = "Molette",
    [245] = "T", [311] = "K",
}

---Update InstructionalButtons
---@param buttons any
local function updateInstructionalButtons(buttons)
    if parametersButtons.hide then
        buttons = {}
    end

    if activeThread then
        activeThread = nil
    end
    if currentScaleform then
        SetScaleformMovieAsNoLongerNeeded(currentScaleform)
        currentScaleform = nil
    end

    if #buttons == 0 then
        SendNUIMessage({ action = "instructionalBar:hide" })
        return
    end

    local items = {}
    for _, button in ipairs(buttons) do
        local keys = { controlKeyMap[button.control] or tostring(button.control) }
        if button.control2 then
            table.insert(keys, controlKeyMap[button.control2] or tostring(button.control2))
        end
        table.insert(items, {
            keys = keys,
            label = button.label
        })
    end

    SendNUIMessage({
        action = "instructionalBar:show",
        data = { items = items }
    })
end

local tableButtons = {}

instructionalButtons = createVariableWatcher(tableButtons, function(key, oldValue, newValue)
    local combinedButtons = {}

    for _, buttons in pairs(tableButtons) do
        for _, button in pairs(buttons) do
            table.insert(combinedButtons, button)
        end
    end

    updateInstructionalButtons(combinedButtons)
end)

parametersInstructionalButtons = createVariableWatcher(parametersButtons, function(key, oldValue, newValue)
    local combinedButtons = {}

    for _, buttons in pairs(tableButtons) do
        for _, button in pairs(buttons) do
            table.insert(combinedButtons, button)
        end
    end

    updateInstructionalButtons(combinedButtons)
end)

---Create InstrucButtons
---@return number|table|boolean Created object or success status
function CreateInstrucButtons()
    return instructionalButtons
end

exports('CreateInstrucButtons', CreateInstrucButtons)
exports('generateUniqueID', generateUniqueID)
exports('AddInstructionalButtons', function(buttons) return VFW.AddInstructionalButtons(buttons) end)
exports('RemoveInstructionalButtons', function(id) VFW.RemoveInstructionalButtons(id) end)

--- Ajouter des boutons instructionnels et retourner l'ID unique pour les supprimer plus tard
---@param buttons table Array de { label = string, control = number, control2? = number }
---@return string id L'identifiant unique pour supprimer ces boutons
function VFW.AddInstructionalButtons(buttons)
    local id = generateUniqueID(8)
    instructionalButtons[id] = buttons
    return id
end

--- Supprimer des boutons instructionnels par leur ID
---@param id string L'identifiant retourné par AddInstructionalButtons
function VFW.RemoveInstructionalButtons(id)
    if id then
        instructionalButtons[id] = nil
    end
end
