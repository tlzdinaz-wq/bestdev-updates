---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.UiLayout = VFW.UiLayout or {}

local KEYS = { "hud", "menu", "notif" }
local serverLayout = {
    hud = "vertical",
    menu = "vertical",
    notif = "vertical",
}

local function norm(value)
    if value == "horizontal" or value == "vertical" then
        return value
    end
    return nil
end

local function playerKey(key)
    return "ui_orient_" .. key
end

function VFW.UiLayout.SetServer(data)
    if type(data) ~= "table" then return end
    for i = 1, #KEYS do
        local key = KEYS[i]
        serverLayout[key] = norm(data[key]) or serverLayout[key]
    end
end

function VFW.UiLayout.GetPlayer(key)
    return norm(GetResourceKvpString(playerKey(key)))
end

function VFW.UiLayout.SetPlayer(key, value)
    if key ~= "hud" and key ~= "menu" and key ~= "notif" then return end
    local next = norm(value)
    if next then
        SetResourceKvp(playerKey(key), next)
    else
        DeleteResourceKvp(playerKey(key))
    end
    VFW.UiLayout.Apply()
end

function VFW.UiLayout.Resolve()
    local out = {}
    for i = 1, #KEYS do
        local key = KEYS[i]
        out[key] = VFW.UiLayout.GetPlayer(key) or serverLayout[key] or "vertical"
    end
    return out
end

function VFW.UiLayout.Apply()
    local resolved = VFW.UiLayout.Resolve()
    SendNUIMessage({
        action = "nui:ui:orientation",
        data = resolved,
    })
    pcall(function()
        exports["VUI"]:SetMenuOrientation(resolved.menu)
    end)
end

function VFW.UiLayout.IndexFor(key)
    local saved = VFW.UiLayout.GetPlayer(key)
    if saved == "horizontal" then return 2 end
    if saved == "vertical" then return 3 end
    return 1
end

local function pullServer()
    local data = TriggerServerCallback("uiLayout:get")
    if type(data) == "table" then
        VFW.UiLayout.SetServer(data)
        if type(data.positions) == "table" and VFW.HudLayout and VFW.HudLayout.SetServer then
            VFW.HudLayout.SetServer(data.positions, false)
        end
    end
    VFW.UiLayout.Apply()
end

RegisterNetEvent("core:ui:orientation", function(data)
    VFW.UiLayout.SetServer(data)
    VFW.UiLayout.Apply()
end)

CreateThread(function()
    for _ = 1, 8 do
        Wait(750)
        local ok = pcall(pullServer)
        if ok and VFW.HudLayout and VFW.HudLayout.SetServer then
            break
        end
    end
end)

RegisterNetEvent("vfw:playerLoaded", function()
    CreateThread(function()
        Wait(200)
        pullServer()
    end)
end)

RegisterNetEvent("vfw:characterLoaded", function()
    CreateThread(function()
        Wait(200)
        pullServer()
    end)
end)
