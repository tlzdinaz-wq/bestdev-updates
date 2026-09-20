---@meta _
---@diagnostic disable: duplicate-doc-field

VFW = exports["core"]:getSharedObject()
VFW.currentResourceName = GetCurrentResourceName()

OnPlayerData = function(key, val, last) end

local _vfwNoopProxy
_vfwNoopProxy = setmetatable({}, {
    __index = function()
        return _vfwNoopProxy
    end,
    __call = function()
        return nil
    end
})

AddEventHandler('onResourceStop', function(resource)
    if resource == 'core' then
        VFW = _vfwNoopProxy
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == 'core' then
        local success, obj
        repeat
            Wait(100)
            success, obj = pcall(exports["core"].getSharedObject, exports["core"])
        until success and obj
        VFW = obj
        VFW.currentResourceName = GetCurrentResourceName()

        if not IsDuplicityVersion() then
            local external = {{"Class", "class.lua"}, {"Point", "point.lua"}}
            for i = 1, #external do
                local module = external[i]
                local path = string.format("client/imports/%s", module[2])
                local file = LoadResourceFile("core", path)
                if file then
                    local fn, err = load(file, ('@@core/%s'):format(path))
                    if fn and not err then
                        VFW[module[1]] = fn()
                    end
                end
            end
        end
    end
end)

if not IsDuplicityVersion() then
---@param key any
---@param val any
---@param last any
    AddEventHandler("vfw:setPlayerData", function(key, val, last)
        if GetInvokingResource() == "core" then
            VFW.PlayerData[key] = val
            if OnPlayerData then
                OnPlayerData(key, val, last)
            end
        end
    end)

---@param xPlayer number|table Player ID or object
    RegisterNetEvent("vfw:playerLoaded", function(xPlayer)
        VFW.PlayerData = xPlayer
        while not VFW.PlayerData.ped or not DoesEntityExist(VFW.PlayerData.ped) do
            Wait(0)
        end

        VFW.PlayerLoaded = true
    end)

    RegisterNetEvent("vfw:onPlayerLogout", function()
        VFW.PlayerLoaded = false
        VFW.PlayerData = {}
    end)

    local external = {{"Class", "class.lua"}, {"Point", "point.lua"}}

    for i = 1, #external do
        local module = external[i]
        local path = string.format("client/imports/%s", module[2])

        local file = LoadResourceFile("core", path)
        if file then
            local fn, err = load(file, ('@@core/%s'):format(path))

            if not fn or err then
                return error(('\n^1Error importing module (%s)'):format(
                                 external[i]))
            end

            VFW[module[1]] = fn()
        else
            return error(('\n^1Error loading module (%s)'):format(external[i]))
        end
    end
end