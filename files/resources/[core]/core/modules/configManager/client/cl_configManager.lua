---@meta _
---@diagnostic disable: duplicate-doc-field

---@class ConfigManager
ConfigManager = {
    Loaded = false,
    Config = {}
}

CreateThread(function()
    while not (TriggerServerCallback) do Wait(100) end
    Wait(5000)
    ConfigManager.Config = TriggerServerCallback("ConfigManager:getConfig")
    ConfigManager.Loaded = true
end)