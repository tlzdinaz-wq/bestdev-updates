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

-- Mugshot de la tuile « Personnage ».
--
-- La prise automatique du mugshot à la connexion était désactivée depuis toujours, un
-- TODO laissé dans 000_framework/client/005_events.lua : `characters.mugshot` restait
-- vide et la tuile retombait sur son image générique.
--
-- Rien à photographier ni à téléverser pour autant : le jeu sait produire un portrait du
-- ped, et FiveM sait exposer une texture de jeu à l'interface par `nui-img`. L'image est
-- donc fabriquée sur place, sans passer par le serveur ni par un hébergeur.
--
-- Elle ne vaut que pour ce joueur, sur sa machine : c'est exactement ce que demande le
-- menu pause. Un mugshot enregistré en base, lui, reste prioritaire — il est partagé,
-- celui-ci non.
local headshot = { handle = nil, url = nil }

local function releaseHeadshot()
    if headshot.handle and IsPedheadshotValid(headshot.handle) then
        UnregisterPedheadshot(headshot.handle)
    end
    headshot.handle, headshot.url = nil, nil
end

--- Fabrique le portrait du ped courant.
---
--- Les portraits de ped sont une ressource rare du moteur : on relâche toujours le
--- précédent avant d'en demander un autre, sinon le pool s'épuise et plus personne n'en
--- obtient.
local function refreshHeadshot()
    local ped = PlayerPedId()
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    releaseHeadshot()

    local handle = RegisterPedheadshotTransparent(ped)
    if not handle or handle == 0 then return end

    local waited = 0
    while not IsPedheadshotReady(handle) and waited < 300 do
        Wait(10)
        waited = waited + 1
    end

    if not IsPedheadshotReady(handle) then
        if IsPedheadshotValid(handle) then UnregisterPedheadshot(handle) end
        return
    end

    local txd = GetPedheadshotTxdString(handle)
    if type(txd) ~= "string" or txd == "" then
        UnregisterPedheadshot(handle)
        return
    end

    headshot.handle = handle
    headshot.url = ("https://nui-img/%s/%s"):format(txd, txd)
end

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
    local stored = resolveUrl(pd.mugshot or "")
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
        -- Le mugshot enregistré prime : il est partagé avec les autres joueurs. À défaut,
        -- le portrait fabriqué à l'instant, qui ne vaut que sur cette machine.
        mugshot = stored ~= "" and stored or (headshot.url or ""),
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

    -- Le portrait demande quelques images au moteur : on ouvre le menu tout de suite et
    -- on renvoie la tuile dès qu'il est prêt, plutôt que de retarder l'ouverture.
    if not headshot.url then
        CreateThread(function()
            refreshHeadshot()
            if menuOpen and headshot.url then
                SendNUIMessage({ action = "pausemenu:open", data = payload() })
            end
        end)
    end
    if VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(true)
    else
        SetNuiFocus(true, true)
    end

    -- Filet : si une autre interface relâche le curseur pendant que le menu est ouvert
    -- (menu contextuel qui se ferme, inventaire…), on le reprend.
    CreateThread(function()
        while menuOpen do
            Wait(250)
            if menuOpen and VFW.Nui and VFW.Nui.HasCursor and not VFW.Nui.HasCursor() then
                if VFW.Nui.Focus then
                    VFW.Nui.Focus(true)
                else
                    SetNuiFocus(true, true)
                end
            end
        end
    end)
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

-- Changement de personnage ou de tenue : le portrait précédent ne correspond plus. On le
-- relâche, le prochain menu en fabriquera un autre.
for _, event in ipairs({
    "vfw:onPlayerLogout", "vfw:playerLoaded",
    "skinchanger:modelLoaded", "skinchanger:loadClothes",
}) do
    AddEventHandler(event, releaseHeadshot)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then releaseHeadshot() end
end)
