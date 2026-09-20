---@meta _
---@diagnostic disable: duplicate-doc-field

-- Positions persistantes du HUD (minimap, statut, vie, compteur, logo, menu VUI).
-- F5 → Options VUI → « Déplacer les interfaces » : glisser à la souris.

local KVP = "hud_layout_v1"
local SERVER_KVP = "hud_layout_server_v1"

local DEFAULTS = {
    minimap = { x = 0.6, y = 79.2, w = 15.0, h = 18.9 },
    status  = { x = 17.0, y = 85.0, w = 16.0, h = 12.0 },
    health  = { x = 2.0,  y = 96.4, w = 16.0, h = 3.0 },
    speedo  = { x = 78.0, y = 86.0, w = 20.0, h = 12.0 },
    logo    = { x = 86.0, y = 1.2,  w = 12.0, h = 10.0 },
    vui     = { x = 2.0,  y = 2.2,  w = 26.0, h = 42.0 },
    notif   = { x = 1.2,  y = 28.0, w = 22.0, h = 28.0 },
}

-- Fiche joueur staff : positionnée seulement dans Gestion, jamais dans le F5.
local SERVER_ONLY = { preview = true }

local layout = nil
local editing = false
local editingServer = false
local backup = nil
local previewMenu = nil
local serverLayout = nil
local personalLayout = nil
local skipPersonalSave = false

local function copy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == "table" and copy(v) or v
    end
    return out
end

local function safezonePad()
    local safezone = tonumber(GetSafeZoneSize()) or 1.0
    return (1.0 / 20.0) * math.abs(safezone - 1.0) * 10.0
end

local function defaultNativeMinimap()
    local posX, posY = -0.0045, 0.012
    local ratio = tonumber(string.format("%.2f", GetScreenAspectRatio())) or 1.78
    if ratio >= 2.3 then
        posX = -0.17
    end
    return posX, posY, 0.150, 0.188888, "B"
end

local function defaultMinimapBox()
    local pad = safezonePad()
    local posX, posY, sizeX, sizeY = defaultNativeMinimap()
    local left = pad + posX
    local bottom = 1.0 - pad - posY
    return {
        x = left * 100,
        y = (bottom - sizeY) * 100,
        w = sizeX * 100,
        h = sizeY * 100,
    }
end

local function defaultPreviewBox(vui)
    vui = type(vui) == "table" and vui or DEFAULTS.vui
    local w, h = 22.0, 70.0
    local x = (tonumber(vui.x) or 2.0) + (tonumber(vui.w) or 26.0) + 1.5
    local y = tonumber(vui.y) or 2.2
    if x + w > 98.0 then
        x = math.max(0.5, (tonumber(vui.x) or 2.0) - w - 1.5)
    end
    return { x = x, y = y, w = w, h = h }
end

local function mergeDefaults(data)
    local out = copy(DEFAULTS)
    out.minimap = defaultMinimapBox()
    if type(data) ~= "table" then return out end
    for id, def in pairs(DEFAULTS) do
        local src = data[id]
        if type(src) == "table" then
            local fallback = id == "minimap" and out.minimap or def
            out[id] = {
                x = tonumber(src.x) or fallback.x,
                y = tonumber(src.y) or fallback.y,
                w = tonumber(src.w) or fallback.w,
                h = tonumber(src.h) or fallback.h,
            }
        end
    end
    local preview = data.preview
    if type(preview) == "table" and tonumber(preview.x) and tonumber(preview.y) then
        local fallback = defaultPreviewBox(out.vui)
        out.preview = {
            x = tonumber(preview.x) or fallback.x,
            y = tonumber(preview.y) or fallback.y,
            w = tonumber(preview.w) or fallback.w,
            h = tonumber(preview.h) or fallback.h,
        }
    end
    if data.custom == true then
        out.custom = true
    end
    return out
end

local function stripServerOnly(data)
    if type(data) ~= "table" then return data end
    for id in pairs(SERVER_ONLY) do
        data[id] = nil
    end
    return data
end

local function ensureServerPreview(data)
    if type(data) ~= "table" then return data end
    if type(data.preview) ~= "table" or not tonumber(data.preview.x) then
        data.preview = defaultPreviewBox(data.vui)
    end
    return data
end

local function hasBoxes(data)
    if type(data) ~= "table" then return false end
    for id in pairs(DEFAULTS) do
        local box = data[id]
        if type(box) == "table" and tonumber(box.x) and tonumber(box.y) then
            return true
        end
    end
    return false
end

local function isPlayerOverride(data)
    return type(data) == "table" and data.custom == true and hasBoxes(data)
end

local function kvpKey()
    local data = VFW.PlayerData
    local id = data and (data.charId or data.identifier or data.charNum)
    if id then
        return ("%s_%s"):format(KVP, tostring(id))
    end
    return KVP
end

local function writeKvp(data)
    SetResourceKvp(kvpKey(), json.encode(data))
end

local function rememberPersonal(data)
    if not hasBoxes(data) then return nil end
    personalLayout = stripServerOnly(mergeDefaults(data))
    personalLayout.custom = true
    writeKvp(personalLayout)
    return personalLayout
end

local function rememberServer(data)
    if not hasBoxes(data) then return nil end
    serverLayout = mergeDefaults(data)
    SetResourceKvp(SERVER_KVP, json.encode(serverLayout))
    return serverLayout
end

local function metadataLayout()
    local meta = VFW.PlayerData and VFW.PlayerData.metadata and VFW.PlayerData.metadata.hudLayout
    if isPlayerOverride(meta) then
        return mergeDefaults(meta)
    end
    return nil
end

local function readKvpKey(key)
    local raw = GetResourceKvpString(key)
    if type(raw) ~= "string" or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if ok and isPlayerOverride(decoded) then
        return mergeDefaults(decoded)
    end
    return nil
end

local function readAnyBoxes(key)
    local raw = GetResourceKvpString(key)
    if type(raw) ~= "string" or raw == "" then return nil end
    local ok, decoded = pcall(json.decode, raw)
    if ok and hasBoxes(decoded) then
        return mergeDefaults(decoded)
    end
    return nil
end

local function readPersonalKvp()
    local data = VFW.PlayerData
    local id = data and (data.charId or data.identifier or data.charNum)
    if not id then return nil end
    return readKvpKey(("%s_%s"):format(KVP, tostring(id)))
end

local function readServerCache()
    return readAnyBoxes(SERVER_KVP)
end

local function loadLayout()
    if isPlayerOverride(personalLayout) then
        return copy(personalLayout)
    end
    local fromMeta = metadataLayout()
    if fromMeta then
        personalLayout = copy(fromMeta)
        writeKvp(personalLayout)
        return copy(personalLayout)
    end
    local fromKvp = readPersonalKvp()
    if fromKvp then
        personalLayout = fromKvp
        return copy(personalLayout)
    end
    personalLayout = nil
    if not serverLayout then
        serverLayout = readServerCache()
    end
    if serverLayout then
        return copy(serverLayout)
    end
    return mergeDefaults(nil)
end

local function saveLayout(data)
    local payload = mergeDefaults(data)
    payload.custom = true
    layout = rememberPersonal(payload)
    local res = TriggerServerCallback("hudLayout:saveMine", { layout = layout })
    return type(res) == "table" and res.ok == true
end

local function hasCustom()
    if isPlayerOverride(personalLayout) then return true end
    if metadataLayout() then return true end
    return readPersonalKvp() ~= nil
end

local function hasPlacedLayout()
    return hasCustom() or serverLayout ~= nil or editing
end

local function boxToNative(box)
    box = box or DEFAULTS.minimap
    local pad = safezonePad()
    -- Même repère que le cadre (haut-gauche). "B" inversait le Y : monter le cadre descendait la carte.
    local posX = (box.x or 0.6) / 100 - pad
    local posY = (box.y or 79.2) / 100 - pad
    local sizeX = (box.w or 15.0) / 100
    local sizeY = (box.h or 18.9) / 100
    return posX, posY, sizeX, sizeY, "T"
end

local function setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
    alignY = alignY or "T"
    local maskY = posY + 0.03
    local blurY = alignY == "T" and (posY - 0.02) or (posY + 0.02)
    SetMinimapComponentPosition("minimap", "L", alignY, posX, posY, sizeX, sizeY)
    SetMinimapComponentPosition("minimap_mask", "L", alignY, posX + 0.0155, maskY, sizeX * 0.74, sizeY * 0.84)
    SetMinimapComponentPosition("minimap_blur", "L", alignY, posX - 0.0255, blurY, sizeX * 1.77, sizeY * 1.26)
end

local function nativeFromLayout(box)
    if hasPlacedLayout() then
        return boxToNative(box or (layout and layout.minimap) or defaultMinimapBox())
    end
    return defaultNativeMinimap()
end

local refreshQueued = false

local function queueRadarRefresh()
    if refreshQueued then return end
    refreshQueued = true
    CreateThread(function()
        Wait(50)
        refreshQueued = false
        local posX, posY, sizeX, sizeY, alignY = nativeFromLayout(layout and layout.minimap)
        setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
        DisplayRadar(false)
        SetRadarBigmapEnabled(true, false)
        Wait(0)
        SetRadarBigmapEnabled(false, false)
        DisplayRadar(true)
        SetRadarZoom(1200)
        posX, posY, sizeX, sizeY, alignY = nativeFromLayout(layout and layout.minimap)
        setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
    end)
end

local function applyMinimap(box, refresh)
    local posX, posY, sizeX, sizeY, alignY = nativeFromLayout(box or (layout and layout.minimap))
    setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
    DisplayRadar(true)
    if refresh then
        queueRadarRefresh()
    end
end

local function applyNui(data)
    SendNUIMessage({
        action = "nui:hudlayout:apply",
        data = data or layout or DEFAULTS,
    })
end

local function pushStatusAnchor()
    SendNUIMessage({
        action = "nui:StatusHUD:position",
        data = VFW.HudLayout.GetAnchor()
    })
end

local function applyVuiOffset(persist)
    pcall(function()
        if hasPlacedLayout() and layout and layout.vui then
            local box = layout.vui
            exports["VUI"]:SetMenuOffset(box.x, box.y, persist ~= false, box.w)
        else
            exports["VUI"]:SetMenuOffset(nil)
        end
    end)
end

local function applyPreviewOffset(persist)
    pcall(function()
        local box
        if editing and editingServer and layout and layout.preview then
            box = layout.preview
        elseif serverLayout and serverLayout.preview then
            box = serverLayout.preview
        end
        if box then
            exports["VUI"]:SetPreviewOffset(box.x, box.y, persist ~= false, box.w, box.h)
        else
            exports["VUI"]:SetPreviewOffset(nil)
        end
    end)
end

local function applyAll(refreshMinimap, reload)
    if reload then
        layout = loadLayout()
    else
        layout = layout or loadLayout()
    end
    applyMinimap(layout.minimap, refreshMinimap ~= false)
    applyNui(layout)
    applyVuiOffset()
    applyPreviewOffset()
    pushStatusAnchor()
end

local function focusEditor()
    if VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(true)
    else
        SetNuiFocus(true, true)
    end
end

local function ensurePreviewMenu()
    if previewMenu then return previewMenu end
    local banner = GetVUIBanner and GetVUIBanner("f5") or nil
    previewMenu = exports["VUI"]:CreateMenu("Menu Personnel", banner, false)
    previewMenu.Button("Inventaire", "Aperçu — le menu suit le cadre", nil, "inventory", true, function() end)
    previewMenu.Button("Animations", "Aperçu de position", nil, "emote", true, function() end)
    previewMenu.Button("Options visuelles", "Aperçu de position", nil, "eye", true, function() end)
    previewMenu.Separator("Aperçu")
    previewMenu.Button("Glisse le cadre Menu VUI", "Les vrais menus s'ouvriront ici", nil, "chevron", true, function() end)
    previewMenu.OnClose(function()
        if not editing then return end
        CreateThread(function()
            Wait(80)
            if editing and previewMenu and not previewMenu.opened then
                previewMenu.open()
                showFichePreview()
                focusEditor()
            end
        end)
    end)
    return previewMenu
end

local function showFichePreview()
    if not editingServer or not previewMenu then return end
    local payload = {
        { type = "header", iconUrl = "people.png", label = "", value = "Aperçu fiche" },
        { type = "body", iconUrl = "people.png", label = "ID Session", value = "2" },
        { type = "body", iconUrl = "data.png", label = "UUID", value = "—" },
        { type = "body", iconUrl = "shield.png", label = "Rôle", value = "Staff" },
        { type = "body", iconUrl = "time.png", label = "Temps de jeu", value = "00:00:00" },
        { type = "body", iconUrl = "people.png", label = "Nom Prénom RP", value = "Aperçu" },
        { type = "body", iconUrl = "time.png", label = "Date de naissance", value = "—" },
        { type = "body", iconUrl = "people.png", label = "Taille", value = "—" },
        { type = "body", iconUrl = "people.png", label = "Sexe", value = "—" },
        { type = "body", iconUrl = "job.png", label = "Job 1", value = "—" },
        { type = "body", iconUrl = "crew.png", label = "Job 2 (Faction)", value = "—" },
        { type = "body", iconUrl = "time.png", label = "TIG", value = "Aucun" },
        { type = "body", iconUrl = "data.png", label = "Instance", value = "Aucune instance" },
    }
    local stats = {
        { "ID Discord", "—" },
        { "Nombre de sanctions reçues", 0 },
    }
    local function send()
        if not editing or not editingServer or not previewMenu then return end
        previewMenu.PlayerPreview(nil, 0xFFFFFF, payload, stats)
    end
    send()
    CreateThread(function()
        Wait(120)
        send()
        Wait(250)
        send()
    end)
end

local function openPreviewMenu()
    pcall(function()
        local menu = ensurePreviewMenu()
        applyVuiOffset(false)
        applyPreviewOffset(false)
        if menu and not menu.opened then
            menu.open()
        end
        showFichePreview()
    end)
    CreateThread(function()
        Wait(50)
        if editing then
            focusEditor()
        end
    end)
end

local function closePreviewMenu()
    pcall(function()
        exports["VUI"]:CloseAll()
    end)
end

VFW.HudLayout = {}

function VFW.HudLayout.GetAnchor()
    layout = layout or loadLayout()
    local box = layout.minimap
    local res_x, res_y = GetActiveScreenResolution()
    local left_x = (box.x or 0.6) / 100
    local top_y = (box.y or 79.2) / 100
    local mmWidth = (box.w or 15.0) / 100
    local mmHeight = (box.h or 18.9) / 100
    return {
        width = mmWidth,
        height = mmHeight,
        left_x = left_x,
        top_y = top_y,
        right_x = left_x + mmWidth,
        bottom_y = top_y + mmHeight,
        width_px = mmWidth * res_x,
        height_px = mmHeight * res_y,
        left_px = left_x * res_x,
        right_px = (left_x + mmWidth) * res_x,
        top_px = top_y * res_y,
        bottom_px = (top_y + mmHeight) * res_y,
        res_x = res_x,
        res_y = res_y,
    }
end

function VFW.HudLayout.ApplyMinimap(refresh)
    layout = layout or loadLayout()
    applyMinimap(layout.minimap, refresh ~= false)
end

function VFW.HudLayout.IsEditing()
    return editing
end

function VFW.HudLayout.SetServer(data, _force)
    if type(data) ~= "table" or not hasBoxes(data) then return end
    rememberServer(data)
    applyPreviewOffset()
    if editing or hasCustom() then return end
    layout = copy(serverLayout)
    applyAll(true)
end

function VFW.HudLayout.StartEditor(mode)
    if editing then return end
    editingServer = mode == "server"
    if editingServer then
        serverLayout = serverLayout or readServerCache()
        layout = ensureServerPreview(copy(serverLayout or loadLayout()))
    else
        layout = stripServerOnly(loadLayout())
    end
    backup = copy(layout)
    skipPersonalSave = false
    editing = true
    pcall(function()
        exports["VUI"]:CloseAll()
    end)
    DisplayRadar(true)
    if VFW.Nui and VFW.Nui.HudVisible then
        VFW.Nui.HudVisible(true)
    end
    if ShowStatusHUD then
        ShowStatusHUD(true)
    end
    SendNUIMessage({ action = "nui:logo:visible", data = true })
    SendNUIMessage({ action = "nui:igInfo:visible", data = true })
    SendNUIMessage({
        action = "nui:speedometer:visible",
        data = {
            visible = true,
            fuelState = 70,
            speedState = 0,
            motorState = 80,
            HeadlightTop = false,
            HeadlightBottom = true,
            TursignalLeft = false,
            TursignalRight = false,
            isSiren = false,
            isSirenSound = false,
            is911 = false,
        }
    })
    applyNui(layout)
    applyMinimap(layout.minimap, true)
    applyVuiOffset(false)
    applyPreviewOffset(false)
    SendNUIMessage({
        action = "nui:hudlayout:edit",
        data = layout,
        scope = editingServer and "server" or "player",
    })
    openPreviewMenu()
    focusEditor()
    if VFW.PreviewNotificaions then
        VFW.PreviewNotificaions({
            type = "INFO",
            subtitle = "Notifications",
            title = "Aperçu",
            message = "Les notifications s'affichent ici.",
            content = "Les notifications s'affichent ici.",
            duration = 120,
        })
    end
    VFW.ShowNotification({
        type = "INFO",
        subtitle = "Notifications",
        title = "Aperçu",
        message = "Les notifications s'affichent ici.",
        duration = 120,
    })
end

function VFW.HudLayout.StopEditor(save)
    if not editing then return end
    local wasServer = editingServer
    editing = false
    editingServer = false
    if save then
        if wasServer then
            local res = TriggerServerCallback("gestionUiLayout:savePositions", { layout = layout })
            if type(res) == "table" and res.ok then
                rememberServer(layout)
                VFW.ShowNotification({
                    type = "VERT",
                    content = res.message or "Positions enregistrées pour tout le serveur.",
                })
            else
                VFW.ShowNotification({
                    type = "ROUGE",
                    content = (type(res) == "table" and res.error) or "Impossible d'enregistrer pour le serveur.",
                })
            end
        elseif skipPersonalSave then
            personalLayout = nil
            DeleteResourceKvp(KVP)
            DeleteResourceKvp(kvpKey())
            TriggerServerCallback("hudLayout:clearMine")
            layout = serverLayout and copy(serverLayout) or mergeDefaults(layout)
            VFW.ShowNotification({
                type = "VERT",
                content = "Tu suis à nouveau le layout serveur.",
            })
        else
            local saved = saveLayout(layout)
            VFW.ShowNotification({
                type = saved and "VERT" or "ORANGE",
                content = saved and "Tes positions perso sont enregistrées." or "Positions perso locales enregistrées (serveur indisponible).",
            })
        end
    else
        layout = backup or loadLayout()
        if not hasCustom() and not serverLayout then
            layout = mergeDefaults(nil)
        elseif not hasCustom() and serverLayout then
            layout = copy(serverLayout)
        end
    end
    skipPersonalSave = false
    backup = nil
    if VFW.ClearPreview then
        VFW.ClearPreview()
    end
    closePreviewMenu()
    SendNUIMessage({ action = "nui:hudlayout:close" })
    SendNUIMessage({ action = "nui:speedometer:visible", data = { visible = false } })
    if VFW.Nui and VFW.Nui.Focus then
        VFW.Nui.Focus(false)
    else
        SetNuiFocus(false, false)
    end
    applyAll(true)
end

local function snapToServer()
    serverLayout = serverLayout or readServerCache()
    if not serverLayout then
        local data = TriggerServerCallback("uiLayout:get")
        if type(data) == "table" and hasBoxes(data.positions) then
            rememberServer(data.positions)
        end
    end
    personalLayout = nil
    DeleteResourceKvp(KVP)
    DeleteResourceKvp(kvpKey())
    TriggerServerCallback("hudLayout:clearMine")
    layout = serverLayout and copy(serverLayout) or mergeDefaults(nil)
    applyMinimap(layout.minimap, true)
    applyNui(layout)
    applyVuiOffset()
    applyPreviewOffset()
    pushStatusAnchor()
    return layout
end

function VFW.HudLayout.Reset()
    skipPersonalSave = true
    snapToServer()
    backup = copy(layout)
    if editing then
        if editingServer then
            layout = ensureServerPreview(layout)
        end
        SendNUIMessage({
            action = "nui:hudlayout:set",
            data = layout,
            scope = editingServer and "server" or "player",
        })
        applyVuiOffset(false)
        applyPreviewOffset(false)
    else
        applyAll(true)
    end
    VFW.ShowNotification({
        type = "VERT",
        content = "Positions remises comme dans Gestion serveur.",
    })
end

RegisterNUICallback("nui:hudlayout:preview", function(data, cb)
    cb({ ok = true })
    if not editing or type(data) ~= "table" then return end
    skipPersonalSave = false
    layout = mergeDefaults(data.layout or data)
    if editingServer then
        ensureServerPreview(layout)
    else
        stripServerOnly(layout)
    end
    applyMinimap(layout.minimap, true)
    applyVuiOffset(false)
    applyPreviewOffset(false)
end)

RegisterNUICallback("nui:hudlayout:save", function(data, cb)
    cb({ ok = true })
    if type(data) == "table" and (data.layout or data.minimap) then
        layout = mergeDefaults(data.layout or data)
    end
    VFW.HudLayout.StopEditor(true)
end)

RegisterNUICallback("nui:hudlayout:reset", function(_, cb)
    cb({ ok = true })
    VFW.HudLayout.Reset()
end)

RegisterNUICallback("nui:hudlayout:cancel", function(_, cb)
    cb({ ok = true })
    VFW.HudLayout.StopEditor(false)
end)

local function restoreSaved()
    layout = loadLayout()
    applyAll(true, true)
end

local function applyPersonal(data)
    if editing or not isPlayerOverride(data) then return false end
    rememberPersonal(data)
    layout = copy(personalLayout)
    applyAll(true)
    return true
end

local function pullPersonal()
    local remote = TriggerServerCallback("hudLayout:getMine")
    return applyPersonal(remote)
end

local function pullServerLayout()
    local data = TriggerServerCallback("uiLayout:get")
    if type(data) == "table" and hasBoxes(data.positions) then
        VFW.HudLayout.SetServer(data.positions, false)
        return true
    end
    return false
end

CreateThread(function()
    serverLayout = readServerCache()
    layout = loadLayout()
    applyAll(true)
    Wait(400)
    pullServerLayout()
    Wait(2000)
    applyAll(true, true)
end)

AddEventHandler("onClientResourceStart", function(res)
    if res ~= GetCurrentResourceName() then return end
    serverLayout = serverLayout or readServerCache()
    layout = loadLayout()
end)

RegisterNetEvent("vfw:loadPlayerData", function(playerData)
    if type(playerData) == "table" and type(playerData.metadata) == "table" then
        applyPersonal(playerData.metadata.hudLayout)
    end
end)

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    CreateThread(function()
        if type(playerData) == "table" and type(playerData.metadata) == "table" then
            applyPersonal(playerData.metadata.hudLayout)
        end
        Wait(400)
        restoreSaved()
        pullPersonal()
    end)
end)

RegisterNetEvent("vfw:onPlayerLogout", function()
    personalLayout = nil
    layout = serverLayout and copy(serverLayout) or mergeDefaults(nil)
end)

RegisterNetEvent("vfw:characterLoaded", function()
    CreateThread(function()
        Wait(400)
        restoreSaved()
        pullPersonal()
    end)
end)

RegisterNetEvent("core:hudlayout:personal", function(data)
    applyPersonal(data)
end)

RegisterNetEvent("core:ui:positions", function(data)
    if VFW.HudLayout and VFW.HudLayout.SetServer then
        VFW.HudLayout.SetServer(data, false)
    end
end)

CreateThread(function()
    while true do
        if editing and layout and layout.minimap then
            local posX, posY, sizeX, sizeY, alignY = boxToNative(layout.minimap)
            setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
            DisplayRadar(true)
            Wait(0)
        elseif hasPlacedLayout() and layout and layout.minimap then
            local posX, posY, sizeX, sizeY, alignY = boxToNative(layout.minimap)
            setMinimapComponents(posX, posY, sizeX, sizeY, alignY)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)
