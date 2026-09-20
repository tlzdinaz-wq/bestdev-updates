---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Nui = {}

local DisableControlAction <const> = DisableControlAction
local EnableControlAction <const> = EnableControlAction

-- Global focus tracking: wrap SetNuiFocus to track ALL focus requests (not just VFW.Nui.Focus)
VFW.Nui._hasFocus = false
VFW.Nui._hasCursor = false -- Track cursor separately
VFW.Nui._onExternalFocus = nil -- Callback appelé quand une UI externe prend le focus
local _originalSetNuiFocus = SetNuiFocus
SetNuiFocus = function(hasFocus, hasCursor)
    VFW.Nui._hasFocus = hasFocus or hasCursor
    VFW.Nui._hasCursor = hasCursor
    if hasFocus and VFW.Nui._onExternalFocus then
        VFW.Nui._onExternalFocus()
    end
    return _originalSetNuiFocus(hasFocus, hasCursor)
end

VFW.Nui.HasFocus = function()
    return VFW.Nui._hasFocus
end

VFW.Nui.HasCursor = function()
    return VFW.Nui._hasCursor
end

VFW.Nui.Visible = function(visible)
    SendNUIMessage({
        action = "nui:visible",
        data = visible
    })
end

VFW.Nui.Close = function()
    SendNUIMessage({
        action = "nui:close"
    })
end

VFW.Nui.Focus = function(focus, keep)
    VFW.Nui._hasFocus = focus
    SetNuiFocus(focus, focus)
    SetNuiFocusKeepInput(keep or false)
end

local _focusGraceFrames = 0
CreateThread(function()
    while true do
        if VFW.Nui._hasFocus then
            _focusGraceFrames = 15
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        elseif _focusGraceFrames > 0 then
            _focusGraceFrames = _focusGraceFrames - 1
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            Wait(0)
        else
            Wait(200)
        end
    end
end)



local registered, radialopen = false, false
local REGISTERED_KEYS <const> = { 1, 2, 142, 18, 322, 106, 24, 25, 263, 264, 257, 140, 141, 142, 143 }
---Register CloseRadial
local function registerCloseRadial()
    radialopen = true
    CreateThread(function()
        SetNuiFocusKeepInput(true)
        SetNuiFocus(true, true)
        while radialopen do
            Wait(1)
            for i = 1, #REGISTERED_KEYS do
                DisableControlAction(0, REGISTERED_KEYS[i], true)
            end
        end
    end)
    if registered then
        return
    end

    registered = true
    RegisterNUICallback("nui:radial-menu:close", function()
        for i = 1, #REGISTERED_KEYS do
            EnableControlAction(0, REGISTERED_KEYS[i], true)
        end

        radialopen = false
        RadialOpen = false
        VFW.Nui.Radial(nil, false)
        VFW.Nui.Focus(false)
    end)
end

VFW.Nui.Radial = function(data, visible)
    if data then
        SendNUIMessage({
            action = "nui:radial-menu:data",
            data = data
        })
        registerCloseRadial()
    end

    SendNUIMessage({
        action = "nui:radial-menu:visible",
        data = visible
    })
    radialopen = visible
    VFW.Nui.Focus(visible)
    VFW.DisableEscapeMenu(visible)
    -- VFW.Nui.HudVisible(not visible)
end

RegisterNUICallback("nui:radial-menu:callback", function(data)
    local EXEC <const> = _G[data.button]
    if EXEC then
        if not data then
            return
        end

        if data.args then
            EXEC(data.args)
        else
            if RadialOpen then
                VFW.Nui.Radial(nil, false)
                RadialOpen = false
            end

            EXEC()
        end
    else
        console.debug("No callback found for radial action " .. (data.name or ""))
    end
end)

---@param name string
---@param data table
---@param visible boolean
VFW.Nui.PropertyHabitation = function(name, visiblename, data, visible)
    SendNUIMessage({
        action = name,
        data = data
    })
    SendNUIMessage({
        action = visiblename,
        data = visible
    })
    VFW.Nui.Focus(visible)
end

---@param target? table
---@param hud? table
VFW.Nui.UpdateInventory = function(target, hud)
    local INV <const> = {} -- trigger ?
    SendNUIMessage({
        action = "nui:inventory:update",
        data = {
            inventory = INV,
            target = target,
            hud = hud
        }
    })
end

VFW.Nui.HudVisible = function(visible, notHideTrade)
    SendNUIMessage({
        action = "nui:hud:visible",
        data = visible,
    })
    if not notHideTrade then
        SendNUIMessage({
            action = "nui:itemTrade:visible",
            data = visible,
        })
    end
    if not visible then
        SendNUIMessage({
            action = "nui:helpNotification:hide",
            data = {}
        })
    end

    DisplayRadar(visible)
end

-- Masquer le HUD quand le pause menu est ouvert
CreateThread(function()
    local wasPaused = false
    while true do
        local isPaused = IsPauseMenuActive()
        if isPaused and not wasPaused then
            SendNUIMessage({ action = "nui:hud:visible", data = false })
        elseif not isPaused and wasPaused then
            SendNUIMessage({ action = "nui:hud:visible", data = true })
        end
        wasPaused = isPaused
        Wait(200)
    end
end)

VFW.Nui.NotificationsVisible = function(visible)
    SendNUIMessage({
        action = "nui:hud:notifications-visible",
        data = visible,
    })
end

VFW.Nui.Tablet = function(visible, data)
    SendNUIMessage({
        action = "nui:illegal-tablet:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:illegal-tablet:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
end

VFW.Nui.Creator = function(visible, data)
    
    SendNUIMessage({
        action = "nui:char-creator:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:char-creator:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
end

VFW.Nui.newRadio = function(visible, data)
    SendNUIMessage({
        action = "nui:newRadio:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:newRadio:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible, visible)
    SetNuiFocusKeepInput(visible)
    VFW.DisableEscapeMenu(visible)
end

VFW.Nui.SkateShop = function(visible, data)
    -- 1. Enviamos visibilidad
    SendNUIMessage({
        action = "nui:SkateShop:setVisible",
        data = visible,
    })

    -- 2. Si hay datos (al abrir), los enviamos
    if data then
        SendNUIMessage({
            action = "nui:SkateShop:setData",
            data = data,
        })
    end

    -- 3. Manejo de foco (usando tu librería)
    VFW.Nui.HudVisible(not visible)
    VFW.Nui.Focus(visible)
end
--VFW.Nui.animation = function(visible, data)
--    SendNUIMessage({
--        action = "nui:animation:visible",
--        data = visible,
--    })
--    if data then
--        SendNUIMessage({
--            action = "nui:animation:data",
--            data = data
--        })
--    end
--
--    VFW.Nui.Focus(visible, visible)
--    VFW.DisableEscapeMenu(visible)
--end


VFW.Nui.SecuroServ = function(data, visible)
    SendNUIMessage({
        action = "nui:securoserv:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:securoserv:data",
            data = data,
        })
    end
end

local factionTabletProp = nil
local factionPanelOpen = false

VFW.Nui.FactionGestion = function(visible, data)
    SendNUIMessage({
        action = "nui:orgaManagement:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:orgaManagement:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)

    factionPanelOpen = visible

    if visible then
        CreateThread(function()
            if not factionPanelOpen then return end

            local ped = PlayerPedId()
            local dict = "amb@world_human_seat_wall_tablet@female@base"
            local anim = "base"
            local propModel = "prop_cs_tablet"

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do Wait(10) end

            RequestModel(propModel)
            while not HasModelLoaded(propModel) do Wait(10) end

            factionTabletProp = CreateObject(GetHashKey(propModel), 0.0, 0.0, 0.0, false, true, false)
            AttachEntityToEntity(factionTabletProp, ped, GetPedBoneIndex(ped, 28422),
                -0.01, 0.0, 0.0,
                0.0, 0.0, 0.0,
                true, true, false, true, 1, true
            )

            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)

            while factionPanelOpen do
                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
                Wait(500)
            end

            ClearPedTasks(ped)
            if factionTabletProp and DoesEntityExist(factionTabletProp) then
                DeleteEntity(factionTabletProp)
                factionTabletProp = nil
            end
        end)
    end
end

VFW.Nui.FactionCreation = function(visible, data)
    SendNUIMessage({
        action = "nui:activity-creation:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:activity-creation:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

--- Tutorial HUD (côté de l'écran, pas de focus)
---@param visible boolean
---@param data? table { id, title, skippable, currentStep, totalSteps, step }
VFW.Nui.Tutorial = function(visible, data)
    SendNUIMessage({
        action = "nui:tutorial:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:tutorial:data",
            data = data,
        })
    end
    -- Pas de focus, c'est un HUD constant
end

--- Tutorial tip rapide (sans étapes, coin de l'écran)
---@param visible boolean
---@param data? table { title, description, icon, position }
VFW.Nui.TutorialTip = function(visible, data)
    SendNUIMessage({
        action = "nui:tutorial:tip:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:tutorial:tip:data",
            data = data,
        })
    end
    -- Pas de focus pour les tips rapides
end

-- Legacy alias
VFW.Nui.OpenTutorial = VFW.Nui.Tutorial

VFW.Nui.Multicharacter = function(visible, data)
    SendNUIMessage({
        action = "nui:multichar:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:multichar:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
end

VFW.Nui.EscapeMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:escape-menu:visible",
        data = visible,
    })
    if data then
        data.isFa = GetConvar("core_type", "WL") == "FA"
        SendNUIMessage({
            action = "nui:escape-menu:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)

    if not visible then
        TriggerScreenblurFadeOut(1000)
    end
end

VFW.Nui.animation = function(visible, data)
    SendNUIMessage({
        action = "nui:animation:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:animation:data",
            data = data
        })
    end

    VFW.Nui.Focus(visible, visible)
    VFW.DisableEscapeMenu(visible)
end

VFW.Nui.newanimation = function(visible, data)
    SendNUIMessage({
        action = "nui:newanimation:visible",
        data = visible,
    })
    if data then
       SendNUIMessage({
           action = "nui:newanimation:data",
           data = data
       })
    end

    VFW.Nui.Focus(visible, visible)
    VFW.DisableEscapeMenu(visible)
end

VFW.Nui.refocus = function()
    VFW.Nui.Focus(true, true)
    VFW.DisableEscapeMenu(true)
end


VFW.Nui.deathScreen = function(visible, secToWait, koMode, cause, id)
    secToWait = secToWait or 300
    koMode = koMode or false

    -- Push data BEFORE visible so the React component mounts with the correct timer
    SendNUIMessage({
        action = 'nui:deathscreen:data',
        data = {
            timer = secToWait,
            id = id,
            koMode = koMode,
            cause = cause or "Inconnue"
        }
    })

    SendNUIMessage({
        action = "nui:deathscreen:visible",
        data = visible
    })

    SetNuiFocus(visible, visible)
    SetNuiFocusKeepInput(visible)
    VFW.DisableEscapeMenu(visible)
end


VFW.Nui.updateDeathScreen = function(data)
    SendNUIMessage({
        action = "nui:deathscreen:update",
        data = data
    })
end

-- nui:deathscreen:action callback is registered in 006_death.lua (uses Death.secLeft)
-- nui:deathscreen:hide is handled by VFW.ReviveSelf() in 006_death.lua


VFW.Nui.BigMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:bigmenu:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:bigmenu:setData",
            data = data
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible, true)
    Worlds.Zone.HideInteract(not visible)
    VFW.DisableEscapeMenu(visible)
end

VFW.Nui.UpdateBigMenu = function(data)
    SendNUIMessage({
        action = "nui:bigmenu:setData",
        data = data
    })
end

VFW.Nui.SendNotifToBigMenu = function(data)
    SendNUIMessage({
        action = "nui:bigmenu:notify",
        data = data
    })
end

---@param type any
---@param message string
---@param secondText string
RegisterNetEvent("nui:bigmenu:notify", function(type, message, secondText)
    VFW.Nui.SendNotifToBigMenu({
        type = type,
        message = message,
        secondText = secondText
    })
end)

VFW.Nui.BlipsBuilder = function(visible)

    local blips = {}

    for blipId, blip in pairs(VFW.GetBlipGroups()) do
        table.insert(blips, {
            numero = blip.sprite,
            nom = blip.name,
            taille = blip.scale,
            couleur = blip.color,
            image = blip.sprite,
            positions = blip.coords,
        })
    end

    VFW.Nui.HudVisible(not visible)
    SendNUIMessage({
        action = "nui:blips:visible",
        data = visible
    })
    Wait(10)
    SendNUIMessage({
        action = "nui:blips:blips",
        data = blips
    })
    VFW.Nui.Focus(visible)
end

-- RegisterCommand("blips", function()
    -- VFW.Nui.BlipsBuilder(true)
-- end)

VFW.Nui.TerritoriesMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:territories:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:territories:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

VFW.Nui.TerritoriesInfluence = function(data)
    SendNUIMessage({
        action = "server-gestion-illegal:setInfluences",
        data = data,
    })
end

VFW.Nui.TerritoriesGestion = function(data)
    SendNUIMessage({
        action = "server-gestion-illegal:setTerritories",
        data = data,
    })
end

local kbd_input = nil

--- .Nui.KeyboardInputVisible
---@param visible boolean
---@param keepInput? boolean
function VFW.Nui.KeyboardInputVisible(visible)
    SendNUIMessage({
        action = "nui:keyboardinput:visible",
        data = visible,
    })
    if (not visible) and StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.RestoreGestionHubFocus()
        return
    end
    VFW.Nui.Focus(visible)
end

--- .Nui.KeyboardInput
---@param visible boolean
---@param text string
---@param defaultValue any
---@param keepInput? boolean
---@param options? table { numberOnly?: boolean, maxValue?: number }
function VFW.Nui.KeyboardInput(visible, text, defaultValue, keepInput, options)
    kbd_input = nil

    VFW.Nui.KeyboardInputVisible(visible, keepInput)

    if text then
        local data = {
            title = text,
            defaultValue = defaultValue or "",
        }
        if options then
            data.numberOnly = options.numberOnly
            data.maxValue = options.maxValue
        end
        SendNUIMessage({
            action = "nui:keyboardinput:setData",
            data = data
        })
    end

    while kbd_input == nil do
        Wait(100)
    end

    if kbd_input == "KBD_CANCEL" then
        return ""
    end

    return kbd_input
end

RegisterNUICallback('nui:keyboardinput:response', function(data, cb)
    if not data.value then
        kbd_input = "KBD_CANCEL"
    else
        kbd_input = data.value
    end

    VFW.Nui.KeyboardInputVisible(false)

    cb('ok')
end)

local choice_input = nil

function VFW.Nui.ChoiceInput(title, subtitle, options)
    choice_input = nil

    SendNUIMessage({
        action = "nui:choiceinput:visible",
        data = true,
    })

    SendNUIMessage({
        action = "nui:choiceinput:setData",
        data = {
            title = title or "Choix",
            subtitle = subtitle or nil,
            options = options or {}
        }
    })

    VFW.Nui.Focus(true)

    while choice_input == nil do
        Wait(100)
    end

    if choice_input == "CHOICE_CANCEL" then
        return nil
    end

    return choice_input
end

RegisterNUICallback('nui:choiceinput:response', function(data, cb)
    if not data.value then
        choice_input = "CHOICE_CANCEL"
    else
        choice_input = data.value
    end

    SendNUIMessage({
        action = "nui:choiceinput:visible",
        data = false,
    })

    if StaffMenu and StaffMenu.IsGestionHubOpen and StaffMenu.IsGestionHubOpen() then
        StaffMenu.RestoreGestionHubFocus()
    else
        VFW.Nui.Focus(false)
    end

    cb('ok')
end)

-- ==================== Color Picker ====================

local colorpicker_result = nil

--- .Nui.ColorPickerVisible
---@param visible boolean
function VFW.Nui.ColorPickerVisible(visible)
    SendNUIMessage({
        action = "nui:colorpicker:visible",
        data = visible,
    })
    VFW.Nui.Focus(visible)
end

--- .Nui.ColorPicker
---@param visible boolean
---@param title string
---@param currentColor string|nil Hex color string (e.g., "#FF0000")
---@return string Selected hex color or empty string if cancelled
function VFW.Nui.ColorPicker(visible, title, currentColor)
    colorpicker_result = nil

    VFW.Nui.ColorPickerVisible(visible)

    if visible then
        SendNUIMessage({
            action = "nui:colorpicker:setData",
            data = {
                title = title or "Couleur",
                currentColor = currentColor or "#FFFFFF"
            }
        })

        while colorpicker_result == nil do
            Wait(100)
        end

        if colorpicker_result == "COLORPICKER_CANCEL" then
            return ""
        end

        return colorpicker_result
    end

    return ""
end

RegisterNUICallback('nui:colorpicker:response', function(data, cb)
    if not data.color then
        colorpicker_result = "COLORPICKER_CANCEL"
    else
        colorpicker_result = data.color
    end

    VFW.Nui.ColorPickerVisible(false)

    cb('ok')
end)

-- ==================== Color Text Editor ====================

local colortexteditor_result = nil
local colortexteditor_preview_cb = nil

function VFW.Nui.ColorTextEditorVisible(visible)
    SendNUIMessage({
        action = "nui:colortexteditor:visible",
        data = visible,
    })
    VFW.Nui.Focus(visible)
end

function VFW.Nui.ColorTextEditor(visible, title, currentText, onPreview)
    colortexteditor_result = nil
    colortexteditor_preview_cb = onPreview

    VFW.Nui.ColorTextEditorVisible(visible)

    if visible then
        SendNUIMessage({
            action = "nui:colortexteditor:setData",
            data = {
                title = title or "Texte",
                currentText = currentText or "",
                showPreview = onPreview ~= nil
            }
        })

        while colortexteditor_result == nil do
            Wait(100)
        end

        colortexteditor_preview_cb = nil

        if colortexteditor_result == "COLORTEXTEDITOR_CANCEL" then
            return ""
        end

        return colortexteditor_result
    end

    colortexteditor_preview_cb = nil
    return ""
end

RegisterNUICallback('nui:colortexteditor:response', function(data, cb)
    if not data.value then
        colortexteditor_result = "COLORTEXTEDITOR_CANCEL"
    else
        colortexteditor_result = data.value
    end

    VFW.Nui.ColorTextEditorVisible(false)

    cb('ok')
end)

RegisterNUICallback('nui:colortexteditor:preview', function(data, cb)
    if colortexteditor_preview_cb and data and data.value and data.value ~= "" then
        colortexteditor_preview_cb(data.value)
    end
    cb('ok')
end)

-- ==================== Valide Input ====================

local valide_input = nil
--- .Nui.ValideInput
---@param visible boolean
---@param title any
function VFW.Nui.ValideInput(visible, title)
    valide_input = nil


    SetNuiFocus(true, true)

    SendNUIMessage({
        action = "nui:valideinput:visible",
        data = visible,
    })

    if visible then
        SendNUIMessage({
            action = "nui:valideinput:setData",
            data = title or "Valider"
        })

        while valide_input == nil do
            Wait(100)
        end


        return valide_input
    else
        valide_input = false
    end
end

RegisterNUICallback('nui:valideinput:response', function(data, cb)
    valide_input = data or false


    SendNUIMessage({
        action = "nui:valideinput:visible",
        data = false,
    })

    SetNuiFocus(false, false)


    cb('ok')
end)

local _confirmPopupResolver = nil

RegisterNUICallback("confirmPopup:response", function(data, cb)
    cb({})
    if _confirmPopupResolver then
        _confirmPopupResolver(data.confirmed == true)
        _confirmPopupResolver = nil
    end
end)

function VFW.Nui.ConfirmPopup(title, message, confirmLabel, cancelLabel)
    local p = promise.new()
    _confirmPopupResolver = function(result) p:resolve(result) end
    local prevFocus <const> = VFW.Nui._hasFocus
    VFW.Nui.Focus(true, true)
    SendNUIMessage({ action = "nui:confirmPopup:open", data = {
        title = title,
        message = message,
        confirmLabel = confirmLabel,
        cancelLabel = cancelLabel,
    }})
    local result = Citizen.Await(p)
    if not prevFocus then
        VFW.Nui.Focus(false, false)
    end
    return result
end

VFW.Nui.VehiclesMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:vehicleMenu:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:vehicleMenu:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible, visible)
    VFW.Nui.HudVisible(not visible)
    VFW.DisableEscapeMenu(visible)
end

local progressstate = nil
local progressActive = false
RegisterNUICallback("nui:progress:finish", function(state)
    progressstate = state
end)

function VFW.Nui.IsProgressActive()
    return progressActive
end

local function applyFrenchElision(text)
    if not text then return text end
    text = text:gsub(" de ([AEIOUHYaeiouyh])", " d'%1")
    return text
end

VFW.Nui.ProgressBar = function(title, milliseconds, disableControls, cancellable, allowCamera)
    if VFW.IsInventoryOpen and VFW.IsInventoryOpen() then
        if VFW.ShowNotification then
            VFW.ShowNotification({ type = "ROUGE", content = "Fermez votre inventaire avant de commencer" })
        end
        return false
    end
    VFW.DisableEscapeMenu(true)
    title = applyFrenchElision(title)
    if disableControls then
        SetStanceDisabled(true)
    end
    progressstate = nil
    progressActive = true
    SendNUIMessage({
        action = "nui:progress:start",
        data = {
            milliseconds = milliseconds,
            title = title,
            cancellable = cancellable or false,
        },
    })

    local safetyDeadline = GetGameTimer() + (tonumber(milliseconds) or 5000) + 5000
    local timedOut = false

    if disableControls then
        local movementControls = {
            21, 22, 23, 30, 31, 32, 33, 34, 35, 36, 44,
            59, 60, 71, 72, 75, 76,
        }
        while progressstate == nil do
            if GetGameTimer() >= safetyDeadline then
                timedOut = true
                break
            end
            for i = 1, #movementControls do
                DisableControlAction(0, movementControls[i], true)
            end
            Wait(0)
        end
        SetStanceDisabled(false)
    else
        while progressstate == nil do
            if GetGameTimer() >= safetyDeadline then
                timedOut = true
                break
            end
            Wait(100)
        end
    end

    VFW.DisableEscapeMenu(false)
    progressActive = false

    if timedOut then
        SendNUIMessage({ action = "nui:progress:cancel" })
        progressstate = nil
        return true
    end

    tempProgressstate = progressstate
    progressstate = nil
    return tempProgressstate
end

VFW.Nui.FuelMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:menu-ltd:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:menu-ltd:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

VFW.Nui.ElevatorMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:elevator:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:elevator:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

VFW.Nui.SafeZoneVisible = function(visible)
    SendNUIMessage({
        action = "nui:safezone:visible",
        data = { visible = visible },
    })
end

VFW.Nui.JobMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:job:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:job:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

VFW.Nui.IdentityCard = function(visible, data)
    SendNUIMessage({
        action = "nui:identity:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:identity:data",
            data = data,
        })
    end
end

VFW.Nui.PPA = function(visible, data)
    SendNUIMessage({
        action = "nui:ppa:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:ppa:setData",
            data = data,
        })
    end
end

VFW.Nui.Invoice = function(visible, data)
    SendNUIMessage({
        action = "nui:invoice:visible",
        data = visible
    })
    if data then
        SendNUIMessage({
            action = "nui:invoice:data",
            data = data
        })
    end

    VFW.Nui.Focus(visible)
end

VFW.Nui.Radio = function(visible, data)
    SendNUIMessage({
        action = "nui:radio:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:radio:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible, visible)
end

VFW.Nui.Craft = function(visible, items, inventory, title)
    SendNUIMessage({
        action = "nui:craft:visible",
        data = visible,
    })
    if visible then
        TriggerScreenblurFadeIn(1000)
        SendNUIMessage({
            action = "nui:craft:data",
            data = {
                craft = items,
---@class recipePossible
                recipePossible = {},
                inventory = inventory,
                title = title,
            }
        })
    else
        TriggerScreenblurFadeOut(1000)
    end

    Worlds.Zone.HideInteract(not visible)
    VFW.Nui.HudVisible(not visible)
    VFW.Nui.Focus(visible)
end

VFW.Nui.CraftUpdateInventory = function(inventory)
    SendNUIMessage({
        action = "nui:craft:updateInventory",
        data = inventory
    })
end

VFW.Nui.Recu = function(visible, data)
    SendNUIMessage({
        action = "nui:recu:visible",
        data = visible
    })
    if data then
        SendNUIMessage({
            action = "nui:recu:data",
            data = data
        })
    end

    VFW.Nui.Focus(visible)
end

RegisterNuiCallback("nui:recu:close", function()
    VFW.Nui.Recu(false)
    VFW.Nui.Focus(false)
end)

local dmvSchoolOpen = false
VFW.Nui.DMVSchool = function(visible)
    dmvSchoolOpen = visible

    if visible then
        SendNUIMessage({
            action = "nui:autoecole:data",
            data = VFW.DMVSchool.questions
        })

        -- Bloquer la touche Alt pendant le quiz
        CreateThread(function()
            while dmvSchoolOpen do
                Wait(0)
                DisableControlAction(0, 19, true) -- INPUT_CHARACTER_WHEEL (Alt)
            end
        end)
    end

    SendNUIMessage({
        action = "nui:autoecole:visible",
        data = visible
    })

    VFW.Nui.Focus(visible)
end

VFW.Nui.PoliceID = function(visible, data)
    SendNUIMessage({
        action = "nui:PoliceID:visible",
        data = visible
    })
    if data then
        SendNUIMessage({
            action = "nui:PoliceID:data",
            data = data
        })
    end
end

VFW.Nui.MediaPlayer = function(visible, forTv)
    SendNUIMessage({
        action = "nui:media-player:visible",
        data = visible
    })

    if forTv then
        SendNUIMessage({
            action = "nui:media-player:tv",
            data = forTv
        })
    end

    VFW.Nui.HudVisible(not visible)
    VFW.Nui.Focus(visible)
end

VFW.Nui.NurseMenu = function(visible, data)
    SendNUIMessage({
        action = "nui:nurseMenu:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:nurseMenu:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    Worlds.Zone.HideInteract(not visible)
end

VFW.Nui.InterimInfo = function(visible, data)
    SendNUIMessage({
        action = "nui:interiminfo:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:interiminfo:data",
            data = data,
        })
    end
end

VFW.Nui.UpdateInterimInfo = function(data)
    SendNUIMessage({
        action = "nui:interiminfo:update",
        data = data,
    })
end

VFW.Nui.NextStepInterim = function()
    SendNUIMessage({
        action = "nui:interiminfo:nextStep",
    })
end

VFW.Nui.IllegalCrafting = function(visible, data)
    SendNUIMessage({
        action = "illegalCrafting:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "illegalCrafting:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible, true)
    if Worlds and Worlds.Zone then
        Worlds.Zone.HideInteract(not visible)
    end
end

VFW.Nui.IllegalCraftingUpdate = function(data)
    SendNUIMessage({
        action = "illegalCrafting:data",
        data = data,
    })
end

RegisterNUICallback("illegalCrafting:close", function(_, cb)
    VFW.Nui.IllegalCrafting(false)
    VFW.Nui.Focus(false)
    cb('ok')
end)

RegisterNUICallback("illegalCrafting:craft", function(data, cb)
    TriggerEvent('core:illegalCrafting:craft', data)
    cb('ok')
end)

RegisterNUICallback("illegalCrafting:collectQueue", function(data, cb)
    local result = TriggerServerCallback("illegalBuilder:collectQueueCraft", data.queueId)
    if result and result.success then
        local label = result.label or "objet"
        local qty = result.totalCollected or result.collected or 0
        VFW.ShowNotification({ type = 'VERT', content = string.format("Vous avez récupéré %dx %s", qty, label) })
    else
        VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Impossible de récupérer les objets" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("illegalCrafting:cancelQueue", function(data, cb)
    local result = TriggerServerCallback("illegalBuilder:cancelQueueCraft", data.queueId)
    if result and result.success then
        local label = result.label or "objet"
        local parts = {}
        if result.itemsCollected and result.itemsCollected > 0 then
            local qty = result.itemsCollected * (result.outputQuantity or 1)
            table.insert(parts, string.format("%dx %s récupéré%s", qty, label, qty > 1 and "s" or ""))
        end
        if result.ingredientsRefunded and result.ingredientsRefunded > 0 then
            table.insert(parts, "matériaux restants remboursés")
        end
        local detail = #parts > 0 and (", " .. table.concat(parts, ", ")) or ""
        VFW.ShowNotification({ type = 'JAUNE', content = "Fabrication annulée" .. detail })
    else
        VFW.ShowNotification({ type = 'ROUGE', content = result and result.error or "Impossible d'annuler la fabrication" })
    end
    cb(result or { success = false })
end)

RegisterNUICallback("illegalCrafting:refreshQueue", function(data, cb)
    local stationId = data.stationId
    local queueData = TriggerServerCallback("illegalBuilder:getStationQueue", tonumber(stationId))
    cb(queueData or {})
end)

VFW.Nui.FactionTablet = function(visible, data)
    SendNUIMessage({
        action = "nui:faction-tablet:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:faction-tablet:data",
            data = data,
        })
    end

    VFW.Nui.Focus(visible)
    VFW.Nui.HudVisible(not visible)
    VFW.DisableEscapeMenu(visible)
    if Worlds and Worlds.Zone then
        Worlds.Zone.HideInteract(not visible)
    end
end


-- ==================== Video Controller ====================
local videoControllerOpen = false

AddEventHandler("core:videoController:open", function()
    videoControllerOpen = true
    SendNUIMessage({ action = "nui:videocontroller:visible", data = true })
    VFW.Nui.Focus(true)
end)

AddEventHandler("core:videoController:close", function()
    if not videoControllerOpen then return end
    videoControllerOpen = false
    SendNUIMessage({ action = "nui:videocontroller:visible", data = false })
    VFW.Nui.Focus(false)
end)

AddEventHandler("core:videoController:update", function(data)
    if videoControllerOpen then
        SendNUIMessage({ action = "nui:videocontroller:update", data = data })
    end
end)

RegisterNUICallback("nui:videocontroller:seek", function(data, cb)
    cb("ok")
    TriggerEvent("ptelevision:controllerSeek", data.time)
end)

RegisterNUICallback("nui:videocontroller:playpause", function(data, cb)
    cb("ok")
    TriggerEvent("ptelevision:controllerPlayPause", data.paused, data.currentTime)
end)

RegisterNUICallback("nui:videocontroller:close", function(data, cb)
    cb("ok")
    if videoControllerOpen then
        videoControllerOpen = false
        SendNUIMessage({ action = "nui:videocontroller:visible", data = false })
        VFW.Nui.Focus(false)
        TriggerEvent("ptelevision:controllerClose")
    end
end)

VFW.Nui.WeaponNotification = function(visible, data)
    SendNUIMessage({
        action = "nui:weaponNotification:visible",
        data = visible,
    })
    if data then
        SendNUIMessage({
            action = "nui:weaponNotification:data",
            data = data,
        })
    end
end

-- Global error catcher : reçoit les erreurs JS non gérées + les erreurs
-- catchées par l'InventoryErrorBoundary, et les forward au serveur pour
-- capturer la stack trace complète des crashes UI.
RegisterNUICallback("debug:globalError", function(data, cb)
    cb({})
    local payload = {
        playerId = GetPlayerServerId(PlayerId()),
        playerName = GetPlayerName(PlayerId()),
        kind = data.kind,
        name = data.name,
        message = data.message,
        stack = data.stack,
        source = data.source,
        lineno = data.lineno,
        colno = data.colno,
        time = data.time,
    }
    print(("[UI ERROR] %s: %s"):format(tostring(data.kind), tostring(data.message)))
    if data.stack then
        print(("[UI ERROR] stack:\n%s"):format(tostring(data.stack)))
    end
end)


