---@meta _
---@diagnostic disable: duplicate-doc-field

-- Pause menu cinématique (Échap) : tuiles Personnage / Carte / Boutique / Réglages / Support.

local menuOpen = false
local allowNative = false
local TILE_IDS = { "personnage", "carte", "boutique", "reglages", "support" }
local tileImages = {
    personnage = "",
    carte = "",
    boutique = "",
    reglages = "",
    support = "",
}

local function resolveUrl(path)
    if type(path) ~= "string" or path == "" then return "" end
    if VFW.CdnUrl then return VFW.CdnUrl(path) end
    return path
end

local function applyTileImages(data)
    if type(data) ~= "table" then return end
    for i = 1, #TILE_IDS do
        local id = TILE_IDS[i]
        if type(data[id]) == "string" then
            tileImages[id] = resolveUrl(data[id])
        end
    end
end

local function payload()
    local pd = VFW.PlayerData or {}
    local colors = (BRANDING and BRANDING.colors) or {}
    local links = (BRANDING and BRANDING.links) or {}
    local discord = links.discord or (BRANDING and BRANDING.discord) or ""
    if type(discord) == "string" and discord ~= "" and not discord:match("^https?://") then
        if discord:find("discord%.gg", 1, true) or discord:find("discord.com", 1, true) then
            discord = "https://" .. discord:gsub("^//", "")
        end
    end
    return {
        brand = VFW.BrandName and VFW.BrandName() or (BRANDING and BRANDING.name) or "",
        logo = resolveUrl((BRANDING and BRANDING.logo) or "logo/logo.svg"),
        mugshot = resolveUrl(pd.mugshot or ""),
        firstName = pd.firstName or "",
        lastName = pd.lastName or "",
        discord = discord,
        tiles = {
            personnage = tileImages.personnage or "",
            carte = tileImages.carte or "",
            boutique = tileImages.boutique or "",
            reglages = tileImages.reglages or "",
            support = tileImages.support or "",
        },
        colors = {
            primary = colors.primary or "#7263EE",
            primaryDark = colors.primaryDark or "#40378A",
        },
    }
end

local function canToggle()
    if allowNative then return false end
    if not VFW.IsPlayerLoaded or not VFW.IsPlayerLoaded() then return false end
    if VFW.IsEscapeMenuDisabled and VFW.IsEscapeMenuDisabled() then return false end
    if VFW.IsOpenEscapeMenu and VFW.IsOpenEscapeMenu() then return false end
    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        if not (StaffMenu.IsGestionHubMinimized and StaffMenu.IsGestionHubMinimized()) then
            return false
        end
    end
    return true
end

local function restoreHud()
    if VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(true)
    end
    DisplayHud(true)
    DisplayRadar(true)
end

local function hideHud()
    if VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(false)
    end
    DisplayHud(false)
    DisplayRadar(false)
end

local function Close(showHud)
    if not menuOpen then return end
    menuOpen = false
    SendNUIMessage({ action = "pausemenu:close" })
    if VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(false)
    else
        SetNuiFocus(false, false)
    end
    if showHud ~= false then
        restoreHud()
    end
end

local function Open()
    if menuOpen then return end
    if VFW.Nui and VFW.Nui.HasFocus and VFW.Nui.HasFocus() then return end
    if IsPauseMenuActive() then return end
    menuOpen = true
    hideHud()
    SendNUIMessage({ action = "pausemenu:open", data = payload() })
    if VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(true)
    else
        SetNuiFocus(true, true)
    end
end

local function Toggle()
    if menuOpen then
        Close(true)
        return
    end
    if not canToggle() then return end
    Open()
end

local function runNative(openFn)
    Close(false)
    allowNative = true
    restoreHud()
    CreateThread(function()
        Wait(80)
        pcall(openFn)
        local seen = false
        local deadline = GetGameTimer() + 3500
        while GetGameTimer() < deadline do
            if IsPauseMenuActive() then
                seen = true
                break
            end
            Wait(50)
        end
        if seen then
            while IsPauseMenuActive() do
                Wait(150)
            end
        end
        allowNative = false
    end)
end

RegisterNuiCallback("pausemenu:close", function(_, cb)
    cb({ ok = true })
    Close(true)
end)

RegisterNuiCallback("pausemenu:select", function(data, cb)
    cb({ ok = true })
    local id = type(data) == "table" and data.id or nil
    CreateThread(function()
        if id == "personnage" then
            Close(true)
            Wait(80)
            ExecuteCommand("relog")
        elseif id == "carte" then
            runNative(function()
                ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, -1)
            end)
        elseif id == "boutique" then
            Close(true)
            Wait(80)
            ExecuteCommand("boutique")
        elseif id == "reglages" then
            runNative(function()
                ActivateFrontendMenu(`FE_MENU_VERSION_MP_PAUSE`, false, 6)
            end)
        elseif id == "support" then
            -- Formulaire NUI : pausemenu:report
        else
            Close(true)
        end
    end)
end)

RegisterNuiCallback("pausemenu:report", function(data, cb)
    local message = type(data) == "table" and data.message or ""
    CreateThread(function()
        local result = TriggerServerCallback("core:pausemenu:report", message)
        if type(result) ~= "table" then
            cb({ ok = false, message = "Envoi impossible." })
            return
        end
        cb(result)
    end)
end)

CreateThread(function()
    while true do
        local nuiFocus = VFW.Nui and VFW.Nui.HasFocus and VFW.Nui.HasFocus()
        if allowNative or menuOpen or nuiFocus or IsPauseMenuActive() then
            Wait(200)
        else
            Wait(0)
            DisableControlAction(0, 200, true)
            if IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(2, 200) then
                Toggle()
            end
        end
    end
end)

RegisterCommand("pausemenu", function()
    Toggle()
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if menuOpen then
        menuOpen = false
        SetNuiFocus(false, false)
        DisplayHud(true)
        DisplayRadar(true)
    end
end)

RegisterNetEvent("core:branding:apply", function()
    if not menuOpen then return end
    SendNUIMessage({ action = "pausemenu:open", data = payload() })
end)

RegisterNetEvent("core:pausemenu:images", function(data)
    applyTileImages(data)
    if menuOpen then
        SendNUIMessage({ action = "pausemenu:open", data = payload() })
    end
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    TriggerServerEvent("core:pausemenu:request")
end)

RegisterNetEvent("vfw:onPlayerLoaded", function()
    TriggerServerEvent("core:pausemenu:request")
end)
