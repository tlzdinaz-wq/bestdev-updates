---@meta _
---@diagnostic disable: duplicate-doc-field

-- Extraire le nom de banner depuis n'importe quel format d'entrée
-- Le NUI React fait : banners/${nom}.webp — on retourne juste le nom
-- Les URLs http/https sont passées telles quelles (le NUI les supporte directement)
local function ResolveBanner(input)
    -- Bannière de marque live (panel EVE, poussée à chaud) : prime sur tout.
    if VUI_BrandBanner and VUI_BrandBanner ~= "" then
        return VUI_BrandBanner
    end
    -- Bannière de marque globale (ConVar core_brand_vui_banner, répliquée par `core`) :
    -- si définie, elle prime sur toutes les bannières des menus VUI (identité unifiée).
    local brandBanner = GetConvar("core_brand_vui_banner", "")
    if brandBanner ~= "" then
        return brandBanner
    end
    if not input or input == "" then return "default" end
    -- Si c'est une URL http/https, la passer telle quelle au NUI
    if input:sub(1, 7) == "http://" or input:sub(1, 8) == "https://" then
        return input
    end
    -- Si c'est un chemin CDN local (contient /), extraire le dernier segment sans extension
    if input:find("/") then
        local filename = input:match("([^/]+)$") or "default"
        return filename:gsub("%.png$", ""):gsub("%.webp$", ""):gsub("%.jpg$", "")
    end
    -- Si c'est déjà un nom avec extension, retirer l'extension
    return input:gsub("%.png$", ""):gsub("%.webp$", ""):gsub("%.jpg$", "")
end

---@class VUIItem
---@field type string Type de l'item ("button"|"checkbox"|"list"|"list2"|"slider"|"separator"|"textbox"|"imagebox"|"title"|"searchinput"|"imagebutton"|"unsearchableButton")
---@field props table Propriétés de l'item (title, subtitle, disabled, etc.)
---@field callback function|nil Fonction appelée lors d'un clic
---@field submenu VUIMenu|nil Sous-menu à ouvrir lors d'un clic
---@field onEnter function|nil Pour List2 : callback sur Entrée
---@field Update fun(props: table) Met à jour les props de l'item à chaud sans rebuild le menu

---@class VUIMenu
---@field title string Titre du menu
---@field banner string URL du banner
---@field index number Index courant du curseur (1-based)
---@field opened boolean Vrai si le menu est actuellement affiché dans le NUI
---@field items VUIItem[] Tous les items (y compris disabled)
---@field filterItems VUIItem[] Items filtrés (si filtre actif)
---@field visibleItems VUIItem[] Items visibles (non-disabled, envoyés au NUI)
---@field autoRefresh boolean Si true, ClearItems() est appelé automatiquement à chaque close()
---@field parent VUIMenu|nil Menu parent (pour la navigation retour)
---@field _isFiltered boolean Vrai si un filtre est actif
---@field _idxChangeFn function|nil Callback OnIndexChange
---@field _closeFn function|nil Callback OnClose
---@field _openFn function|nil Callback OnOpen
---@field _helpButtons table<string, string> Boutons d'aide {key=text}
---@field open fun() Ouvre le menu (si déjà ouvert : ferme + vide la stack)
---@field close fun() Ferme le menu + envoie vui:menu:close au NUI
---@field refresh fun() Sauvegarde l'index → close() → open() ⚠️ cause un flash visuel
---@field toggle fun() open() si fermé, close() si ouvert
---@field ClearItems fun() Vide tous les items, filterItems, visibleItems
---@field OnOpen fun(fn: fun()) Enregistre un callback appelé à chaque ouverture
---@field OnClose fun(fn: fun()) Enregistre un callback appelé à chaque fermeture
---@field OnIndexChange fun(fn: fun(index: number, item: VUIItem)) Callback quand le curseur bouge
---@field AddHelpButton fun(key: string, text: string) Ajoute un bouton d'aide
---@field ChangeBanner fun(banner: string) Change le banner du menu
---@field isFiltered fun(): boolean Retourne vrai si un filtre est actif
---@field filter fun(fn: fun(item: VUIItem): boolean) Filtre les items affichés
---@field removeFilter fun() Retire le filtre actif
---@field Get fun(key: number|string): VUIItem|nil Récupère un item par index ou titre
---@field Button fun(title: string, subtitle: string|nil, rightLabel: string|nil, icon: string|nil, disabled: boolean|nil, callback: fun()|nil, submenu: VUIMenu|nil, index: number|nil, panel: any|nil): VUIItem
---@field UnSearchableButton fun(title: string, subtitle: string|nil, rightLabel: string|nil, icon: string|nil, disabled: boolean|nil, callback: fun()|nil, submenu: VUIMenu|nil, index: number|nil): VUIItem
---@field ImageButton fun(title: string, image: string, disabled: boolean|nil, callback: fun()|nil, submenu: VUIMenu|nil, index: number|nil): VUIItem
---@field SearchInput fun(title: string, disabled: boolean|nil, index: number|nil): VUIItem
---@field Checkbox fun(title: string, subtitle: string|nil, disabled: boolean|nil, checked: boolean, callback: fun(checked: boolean), index: number|nil): VUIItem
---@field List fun(title: string, subtitle: string|nil, disabled: boolean|nil, items: string[], index: number, callback: fun(index: number, value: string)|nil, submenu: VUIMenu|nil, _idx: number|nil): VUIItem
---@field List2 fun(title: string, subtitle: string|nil, disabled: boolean|nil, items: string[], index: number, onArrow: fun(index: number, value: string)|nil, onEnter: fun(index: number, value: string)|nil, _idx: number|nil): VUIItem
---@field Slider fun(title: string, value: number, min: number, max: number, step: number|nil, subtitle: string|nil, disabled: boolean|nil, callback: fun(value: number)|nil, index: number|nil): VUIItem
---@field Separator fun(leftLabel: string|nil, leftValue: string|nil, rightLabel: string|nil, rightValue: string|nil, index: number|nil): VUIItem
---@field Textbox fun(content: string, title: string|nil, index: number|nil): VUIItem
---@field Imagebox fun(image1: string, image2: string|nil, index: number|nil): VUIItem
---@field Title fun(leftLabel: string|nil, leftValue: string|nil, rightLabel: string|nil, rightValue: string|nil, index: number|nil): VUIItem
---@field Footer fun(content: string, index: number|nil)
---@field PlayerPreview fun(image: string|nil, color: string|nil, playerData: table|nil, statistics: table|nil)
---@field ReportPreview fun(reportId: any, reportTime: string, reportMsg: string, reportPlayerName: string, reportPlayerId: number, reportPlayerIdentity: string, reportTakenBy: string|nil, index: number|nil)
---@field CloseReportPreview fun(index: number|nil)
---@field BanPreview fun(banId: any, banRaison: string, banAt: string, banExpiration: string, banIdentifiers: table, index: number|nil)
---@field CloseBanPreview fun(index: number|nil)
---@field WarnPreview fun(warnId: any, warnRaison: string, warnAt: string, warnBy: string, warnLicense: string, warnDiscord: string, index: number|nil)
---@field CloseWarnPreview fun(index: number|nil)
---@field SanctionPreview fun(sanctionId: any, sanctionType: string, sanctionReason: string, sanctionAt: string, sanctionBy: string, sanctionStatus: string, sanctionExtra: any, index: number|nil)
---@field CloseSanctionPreview fun(index: number|nil)
---@field PermissionPreview fun(permName: string, permLabel: string, permDescription: string, permCategory: string, index: number|nil)
---@field ClosePermissionPreview fun(index: number|nil)
---@field CasePreview fun(caseName: string, caseDescription: string, price: number, playerPoints: number, prizes: table, index: number|nil)
---@field CloseCasePreview fun(index: number|nil)
---@field VipPreview fun(tierLabel: string, tierColor: string, spacecoins: number, advantages: table)
---@field CloseVipPreview fun()
---@field ColorPicker fun(primaryR: number, primaryG: number, primaryB: number, secondaryR: number, secondaryG: number, secondaryB: number, onPrimaryChange: fun(r:number,g:number,b:number)|nil, onSecondaryChange: fun(r:number,g:number,b:number)|nil)
---@field CloseColorPicker fun()
---@field RoleColorPicker fun(r: number, g: number, b: number, title: string|nil, onChange: fun(r:number,g:number,b:number)|nil, onValidate: fun(r:number,g:number,b:number)|nil, onCancel: fun()|nil)
---@field CloseRoleColorPicker fun()

VUI_CurrentMenu = nil   ---@type VUIMenu|nil Menu actuellement affiché (nil si aucun)
VUI_LastMenuIndex = {}  ---@type table<string, number> Index sauvegardés par titre de menu (pour restauration)
VUI_IsExitingMenu = false ---@type boolean Flag actif durant la fermeture volontaire
VUI_ColorPickerCallbacks = nil
VUI_RoleColorPickerCallbacks = nil
VUI_MenuStack = {}  ---@type {menu: VUIMenu, savedIndex: number}[] Stack de navigation (pop = retour)
VUI_IsOpening = false  -- Debounce flag to prevent double-open on key spam

-- Bannière de marque live (panel EVE). Si non vide, prime sur la ConVar et sur
-- les bannières par type. Mise à jour à chaud via l'event 'core:vui:setBranding'.
VUI_BrandBanner = ""
-- Registre de TOUS les menus créés (CreateMenu) : permet de réappliquer la
-- bannière de marque à chaud sur les menus déjà instanciés.
-- ⚠️ Set à CLÉS FAIBLES (`__mode = "k"`) : le menu est la clé, `true` la valeur.
-- Un menu recréé dynamiquement (ex. garageIllegal ouvre un nouveau menu à chaque
-- interaction) qui n'est plus référencé ailleurs est automatiquement collecté par
-- le GC et retiré de ce registre → aucune fuite mémoire. Les menus persistants
-- (gardés vivants par un upvalue/variable de module) restent enregistrés.
VUI_AllMenus = setmetatable({}, { __mode = "k" })
VUI_LastBackTime = 0 ---@type number Timestamp du dernier back (debounce 200ms)

-- Mode hub : les menus sont rendus par le hub de gestion de `core` (NUI) au lieu du
-- NUI VUI. Tous les messages "vui:menu*" sont relayés à `core` via l'event local
-- "vui:hub:message" ; les interactions reviennent par les mêmes callbacks NUI
-- (https://VUI/vui:menu:click, ...). Activé par OpenInHub(), désactivé quand la
-- chaîne de menus se ferme (event "vui:hub:ended") ou au retour vers le hub.
VUI_HubMode = false
-- Fermeture interne (open() d'un autre menu, refresh) : ne termine pas le mode hub.
VUI_Switching = false
-- Proxy « retour au hub » : ne pas remonter vers le menu F5 (MENU ADMINISTRATION).
VUI_HubReturnProxy = nil
-- Menus VUI du menu staff : un retour hub ne doit jamais les rouvrir.
local HUB_BLOCKED_PARENTS <const> = {
    ["MENU ADMINISTRATION"] = true,
    ["GESTION DE GLOBAL"] = true,
    ["__return__"] = true,
}

local _SendNUIMessageNative = SendNUIMessage
SendNUIMessage = function(msg)
    if VUI_HubMode and type(msg) == "table" and type(msg.action) == "string" and msg.action:sub(1, 8) == "vui:menu" then
        -- Event local : reçu par tous les handlers client, dont celui de `core`
        TriggerEvent("vui:hub:message", msg)
        return
    end
    return _SendNUIMessageNative(msg)
end

--- Ferme le menu courant ET nettoie tout le stack proprement.
--- Utilisable via exports['VUI']:CloseAll()
function VUI_CloseAll()
    -- Marquer tous les menus du stack comme fermés
    if VUI_MenuStack then
        for i = #VUI_MenuStack, 1, -1 do
            local entry = VUI_MenuStack[i]
            local m = type(entry) == "table" and entry.menu or entry
            if m then m.opened = false end
        end
    end
    VUI_MenuStack = {}
    -- Fermer le menu actif
    if VUI_CurrentMenu then
        VUI_CurrentMenu.close()
    end
end

exports('CloseAll', VUI_CloseAll)

local function ReturnToHub()
    local proxy = VUI_HubReturnProxy
    VUI_HubReturnProxy = nil
    VUI_MenuStack = {}
    if VUI_CurrentMenu and VUI_CurrentMenu._closeInternal then
        VUI_CurrentMenu._closeInternal()
    end
    VUI_CurrentMenu = nil
    if proxy and proxy.open then
        proxy.open()
        return
    end
    SendNUIMessage({ action = "vui:menu:close" })
    VUI_HubMode = false
    TriggerEvent("vui:hub:ended")
end

-- Centralized back handler with debounce to prevent double-fire
-- Both the GTA keybind and the NUI callback trigger back independently
-- when a SearchInput is present, causing double-back or unexpected menu close
function VUI_HandleBack()
    if not VUI_CurrentMenu then return end

    local now = GetGameTimer()
    if now - VUI_LastBackTime < 200 then return end
    VUI_LastBackTime = now

    local entry = table.remove(VUI_MenuStack)
    local backTarget
    local savedIndex

    if entry then
        if type(entry) == "table" and entry.menu then
            backTarget = entry.menu
            savedIndex = entry.savedIndex
        else
            -- Backwards compatibility: old format was just the menu
            backTarget = entry
        end
    end

    -- En mode hub, ne jamais remonter vers le menu F5 via `.parent`
    -- (souvent MENU ADMINISTRATION) si la pile a été vidée (refresh, close…).
    if VUI_HubMode then
        if not backTarget or HUB_BLOCKED_PARENTS[backTarget.title] then
            ReturnToHub()
            return
        end
    else
        backTarget = backTarget or (VUI_CurrentMenu and VUI_CurrentMenu.parent)
    end

    if backTarget and backTarget.open then
        -- Internal close: no vui:menu:close sent to NUI (the next open() will replace it)
        if VUI_CurrentMenu and VUI_CurrentMenu._closeInternal then
            VUI_CurrentMenu._closeInternal()
        end
        VUI_CurrentMenu = backTarget
        -- Restore saved index before open so it's picked up
        if savedIndex and backTarget.title then
            VUI_LastMenuIndex[backTarget.title] = savedIndex
        end
        VUI_CurrentMenu.open()
    else
        VUI_MenuStack = {}
        VUI_IsExitingMenu = true
        VUI_CurrentMenu.close()
        VUI_IsExitingMenu = false
        VUI_CurrentMenu = nil
    end
end

-- Position libre (éditeur) + côté gauche/droite dérivé du cadre.
local runtimeOffset = nil

local function menuSideFromBox(x, w)
    x = tonumber(x) or 2.0
    w = tonumber(w) or 26.0
    return (x + w * 0.5) >= 50.0 and "right" or "left"
end

---@return table|nil
local function GetMenuOffset()
    local raw = GetResourceKvpString("vui_offset")
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return nil
end

local function currentMenuOffset()
    if type(runtimeOffset) == "table" then
        return runtimeOffset
    end
    return GetMenuOffset()
end

-- Position preference (left or right). Si un offset x/y est actif, le côté
-- suit le cadre (pour le logo HUD et les fiches à côté du menu).
---@return "left"|"right"
local function GetMenuPosition()
    local off = currentMenuOffset()
    if off and tonumber(off.x) then
        return menuSideFromBox(off.x, off.w)
    end
    return GetResourceKvpString("vui_position") or "left"
end

local function pushMenuSide(side)
    SendNUIMessage({
        action = "vui:setPosition",
        data = { position = side }
    })
    TriggerEvent("vui:positionChanged", side)
end

---@param pos "left"|"right"
local function SetMenuPosition(pos)
    runtimeOffset = nil
    DeleteResourceKvp("vui_offset")
    SendNUIMessage({
        action = "vui:setOffset",
        data = { enabled = false }
    })
    SetResourceKvp("vui_position", pos)
    pushMenuSide(pos)
end

---@param x number|nil
---@param y number|nil
---@param persist? boolean
---@param w? number
local function SetMenuOffset(x, y, persist, w)
    if persist == nil then persist = true end
    if x == nil then
        runtimeOffset = nil
        if persist then
            DeleteResourceKvp("vui_offset")
        end
        SendNUIMessage({
            action = "vui:setOffset",
            data = { enabled = false }
        })
        pushMenuSide(GetResourceKvpString("vui_position") or "left")
        return
    end
    local ox = tonumber(x) or 2.0
    local oy = tonumber(y) or 2.2
    local ow = tonumber(w) or 26.0
    runtimeOffset = { x = ox, y = oy, w = ow }
    if persist then
        SetResourceKvp("vui_offset", json.encode(runtimeOffset))
    end
    local side = menuSideFromBox(ox, ow)
    SendNUIMessage({
        action = "vui:setOffset",
        data = { enabled = true, x = ox, y = oy, w = ow, side = side }
    })
    -- NUI only : ne pas appeler SetMenuPosition (ça efface l’offset).
    pushMenuSide(side)
end

RegisterNUICallback("vui:getOffset", function(_, cb)
    local off = currentMenuOffset()
    if off and tonumber(off.x) then
        cb({
            enabled = true,
            x = tonumber(off.x),
            y = tonumber(off.y) or 2.2,
            w = tonumber(off.w) or 26.0,
            side = menuSideFromBox(off.x, off.w),
        })
        return
    end
    cb({ enabled = false })
end)

-- Position libre de la fiche joueur (Gestion serveur uniquement).
local runtimePreview = nil

---@return table|nil
local function GetPreviewOffset()
    if type(runtimePreview) == "table" then
        return runtimePreview
    end
    local raw = GetResourceKvpString("vui_preview_offset")
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return nil
end

---@param x number|nil
---@param y number|nil
---@param persist? boolean
---@param w? number
---@param h? number
local function SetPreviewOffset(x, y, persist, w, h)
    if persist == nil then persist = true end
    if x == nil then
        runtimePreview = nil
        if persist then
            DeleteResourceKvp("vui_preview_offset")
        end
        SendNUIMessage({
            action = "vui:setPreviewOffset",
            data = { enabled = false }
        })
        return
    end
    local ox = tonumber(x) or 29.5
    local oy = tonumber(y) or 2.2
    runtimePreview = {
        x = ox,
        y = oy,
        w = tonumber(w) or 22.0,
        h = tonumber(h) or 70.0,
    }
    if persist then
        SetResourceKvp("vui_preview_offset", json.encode(runtimePreview))
    end
    SendNUIMessage({
        action = "vui:setPreviewOffset",
        data = {
            enabled = true,
            x = runtimePreview.x,
            y = runtimePreview.y,
            w = runtimePreview.w,
            h = runtimePreview.h,
        }
    })
end

RegisterNUICallback("vui:getPreviewOffset", function(_, cb)
    local off = GetPreviewOffset()
    if off and tonumber(off.x) then
        cb({
            enabled = true,
            x = tonumber(off.x),
            y = tonumber(off.y) or 2.2,
            w = tonumber(off.w) or 22.0,
            h = tonumber(off.h) or 70.0,
        })
        return
    end
    cb({ enabled = false })
end)

-- Nombre maximum d'items visibles dans un menu VUI (slider personnalisable)
local VUI_MAX_ITEMS_MIN = 4
local VUI_MAX_ITEMS_MAX = 15
local VUI_MAX_ITEMS_DEFAULT = 10

---@return number
local function GetMaxItems()
    local stored = GetResourceKvpInt("vui_max_items")
    if not stored or stored <= 0 then
        return VUI_MAX_ITEMS_DEFAULT
    end
    if stored < VUI_MAX_ITEMS_MIN then return VUI_MAX_ITEMS_MIN end
    if stored > VUI_MAX_ITEMS_MAX then return VUI_MAX_ITEMS_MAX end
    return stored
end

---@param value number
local function SetMaxItems(value)
    value = math.floor(tonumber(value) or VUI_MAX_ITEMS_DEFAULT)
    if value < VUI_MAX_ITEMS_MIN then value = VUI_MAX_ITEMS_MIN end
    if value > VUI_MAX_ITEMS_MAX then value = VUI_MAX_ITEMS_MAX end
    SetResourceKvpInt("vui_max_items", value)
    SendNUIMessage({
        action = "vui:setMaxItems",
        data = { maxItems = value }
    })
    TriggerEvent("vui:maxItemsChanged", value)
end

-- Send position + maxItems to NUI on resource start
AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Citizen.SetTimeout(500, function()
        local pos = GetMenuPosition()
        SendNUIMessage({
            action = "vui:setPosition",
            data = { position = pos }
        })
        TriggerEvent("vui:positionChanged", pos)

        SendNUIMessage({
            action = "vui:setMaxItems",
            data = { maxItems = GetMaxItems() }
        })

        local off = GetMenuOffset()
        if off then
            SetMenuOffset(off.x, off.y, false, off.w)
        end
        local preview = GetPreviewOffset()
        if preview then
            SetPreviewOffset(preview.x, preview.y, false, preview.w, preview.h)
        end
    end)
end)

-- Command to toggle or set position
RegisterCommand("vuipos", function(source, args)
    local pos = args[1]
    if pos == "left" or pos == "right" then
        SetMenuPosition(pos)
        TriggerEvent("chat:addMessage", { args = { "^2[VUI] Position du menu : " .. pos } })
    else
        local current = GetMenuPosition()
        local next = current == "left" and "right" or "left"
        SetMenuPosition(next)
        TriggerEvent("chat:addMessage", { args = { "^2[VUI] Position du menu : " .. next } })
    end
end, false)

exports("SetMenuPosition", SetMenuPosition)
exports("GetMenuPosition", GetMenuPosition)
exports("SetMenuOffset", SetMenuOffset)
exports("GetMenuOffset", GetMenuOffset)
exports("SetPreviewOffset", SetPreviewOffset)
exports("GetPreviewOffset", GetPreviewOffset)

---@param dir "horizontal"|"vertical"|nil
local function SetMenuOrientation(dir)
    if dir ~= "horizontal" then dir = "vertical" end
    SendNUIMessage({
        action = "vui:setOrientation",
        data = { orientation = dir }
    })
end

exports("SetMenuOrientation", SetMenuOrientation)

-- Mise à jour LIVE de la bannière de marque (panel EVE). `core` (branding_nui.lua)
-- déclenche cet event local quand le panel pousse un nouveau banner. Les menus VUI
-- étant créés une fois au boot, on réapplique la bannière sur tous les menus déjà
-- instanciés ET sur le menu actuellement ouvert, sans reconnexion.
AddEventHandler('core:vui:setBanner', function(banner)
    if type(banner) ~= 'string' then return end
    VUI_BrandBanner = banner
    if banner == '' then return end
    for m in pairs(VUI_AllMenus) do
        if type(m) == 'table' then m.banner = banner end
    end
    -- Rafraîchit la bannière du menu ouvert sans reset (items/index conservés).
    if VUI_CurrentMenu and VUI_CurrentMenu.opened then
        SendNUIMessage({ action = 'vui:menu:setBanner', data = { banner = banner } })
    end
end)

---@param t VUIItem[]
---@param item VUIItem
---@param index number|nil
---@return VUIItem
local function AddItem(t, item, index)

    if not index then
        index = #t + 1
    end

    item.Update = function(props)

        for k, v in pairs(props) do
            item.props[k] = v
        end

        SendNUIMessage({
            action = "vui:menu:update",
            data = {
                index = index - 1,
                item = {
                    type = item.type,
                    props = item.props
                }
            }
        })
    end

    table.insert(t, index, item)

    return item
end

--- Crée un menu racine.
---@param title string Titre affiché en haut du menu
---@param banner string URL de l'image banner
---@param autoRefresh boolean|nil Si true, ClearItems() est appelé automatiquement à chaque fermeture
---@return VUIMenu
function CreateMenu(title, banner, autoRefresh)
    local menu = {}
    local crtIdx = 1
    menu.title = title
    menu.banner = ResolveBanner(banner)
    menu.index = 1
    menu.opened = false
    menu.items = {}
    menu.filterItems = {}
    menu.visibleItems = {}
    menu.autoRefresh = autoRefresh or false
    menu._isFiltered = false
    menu._idxChangeFn = nil
    menu._closeFn = nil
    menu._openFn = nil
    menu._helpButtons = {}

    menu.ClearItems = function()
        menu.items = {}
        menu.filterItems = {}
        menu.visibleItems = {}
        menu._isFiltered = false
        menu.index = 1
    end
    menu.OnIndexChange = function(fn)
        menu._idxChangeFn = fn
    end
    menu.OnClose = function(fn)
        menu._closeFn = fn
    end
    menu.OnOpen = function(fn)
        menu._openFn = fn
    end
    menu.AddHelpButton = function(key, text)
        menu._helpButtons[key] = text
    end
    menu.SetTitle = function(newTitle)
        menu.title = newTitle
    end
    menu.SaveIndex = function()
        if menu.title then
            VUI_LastMenuIndex[menu.title] = menu.index
        end
    end
    menu.Footer = function(content, index)
        SendNUIMessage({
            action = "vui:menu:footer",
            data = {
                content = content,
                index = index
            }
        }, index)
    end

    menu.PlayerPreview = function(image, color, playerData, statistics)
        local data = nil

        if playerData then
            data = {
                image = image,
                color = color,
                playerData = playerData,
                statistics = statistics
            }
        end

        SendNUIMessage({
            action = 'vui:menu:playerPreview',
            data = data
        })
    end

    menu.ReportPreview = function(reportId, reportTime, reportMsg, reportPlayerName, reportPlayerId, reportPlayerIdentity, reportTakenBy, index)
        SendNUIMessage({
            action = "vui:menu:reportPreview",
            data = {
                reportId = reportId,
                reportTime = reportTime,
                reportMsg = reportMsg,
                reportPlayerName = reportPlayerName,
                reportPlayerId = reportPlayerId,
                reportPlayerIdentity = reportPlayerIdentity,
                reportTakenBy = reportTakenBy,
                index = index
            }
        }, index)
    end

    menu.CloseReportPreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closeReportPreview",
            data = {
                index = index
            }
        }, index)
    end

    menu.ChangeBanner = function(banner)
        menu.banner = ResolveBanner(banner)
    end

    menu.BanPreview = function(banId, banRaison, banAt, banExpiration, banIdentifiers, index)
        SendNUIMessage({
            action = "vui:menu:banPreview",
            data = {
                banId = banId,
                banRaison = banRaison,
                banAt = banAt,
                banExpiration = banExpiration,
                banIdentifiers = banIdentifiers,
            }
        }, index)
    end
    menu.CloseBanPreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closeBanPreview",
            data = {
                index = index
            }
        }, index)
    end

    menu.WarnPreview = function(warnId, warnRaison, warnAt, warnBy, warnLicense, warnDiscord, index)
        SendNUIMessage({
            action = "vui:menu:warnPreview",
            data = {
                warnId = warnId,
                warnAt = warnAt,
                warnReason = warnRaison,
                warnBy = warnBy,
                warnLicense = warnLicense,
                warnDiscord = warnDiscord
            }
        }, index)
    end
    menu.CloseWarnPreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closeWarnPreview",
            data = {
                index = index
            }
        }, index)
    end

    menu.SanctionPreview = function(sanctionId, sanctionType, sanctionReason, sanctionAt, sanctionBy, sanctionStatus, sanctionExtra, index)
        SendNUIMessage({
            action = "vui:menu:sanctionPreview",
            data = {
                sanctionId = sanctionId,
                sanctionType = sanctionType,
                sanctionReason = sanctionReason,
                sanctionAt = sanctionAt,
                sanctionBy = sanctionBy,
                sanctionStatus = sanctionStatus,
                sanctionExtra = sanctionExtra
            }
        }, index)
    end

    menu.CloseSanctionPreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closeSanctionPreview",
            data = {
                index = index
            }
        }, index)
    end

    menu.PermissionPreview = function(permName, permLabel, permDescription, permCategory, index)
        SendNUIMessage({
            action = "vui:menu:permissionPreview",
            data = {
                permName = permName,
                permLabel = permLabel,
                permDescription = permDescription,
                permCategory = permCategory,
                index = index
            }
        }, index)
    end

    menu.ClosePermissionPreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closePermissionPreview",
            data = {
                index = index
            }
        }, index)
    end

    --- Ajoute un bouton standard.
    ---@param title string Label principal
    ---@param subtitle string|nil Description sous le titre
    ---@param rightLabel string|nil Texte à droite
    ---@param icon string|nil Icône ("chevron" pour sous-menu, nil pour aucune)
    ---@param disabled boolean|nil Si true, l'item est grisé et non-cliquable
    ---@param callback fun()|nil Fonction appelée au clic (retourner false pour annuler la navigation submenu)
    ---@param submenu VUIMenu|nil Sous-menu à ouvrir après le callback
    ---@param index number|nil Position d'insertion (nil = fin)
    ---@param panel any|nil Données panel optionnelles
    ---@return VUIItem
    menu.Button = function(title, subtitle, rightLabel, icon, disabled, callback, submenu, index, panel)
        return AddItem(menu.items, {
            type = "button",
            callback = callback,
            submenu = submenu,
            props = {
                title = title,
                subtitle = subtitle,
                rightLabel = rightLabel,
                icon = icon,
                disabled = disabled,
                panel = panel
            },
        }, index)
    end

    --- Ajoute un bouton exclu de la recherche SearchInput.
    ---@param title string
    ---@param subtitle string|nil
    ---@param rightLabel string|nil
    ---@param icon string|nil
    ---@param disabled boolean|nil
    ---@param callback fun()|nil
    ---@param submenu VUIMenu|nil
    ---@param index number|nil
    ---@return VUIItem
    menu.UnSearchableButton = function(title, subtitle, rightLabel, icon, disabled, callback, submenu, index)
        return AddItem(menu.items, {
            type = "unsearchableButton",
            callback = callback,
            submenu = submenu,
            props = {
                title = title,
                subtitle = subtitle,
                rightLabel = rightLabel,
                icon = icon,
                disabled = disabled
            },
        }, index)
    end

    --- Ajoute un bouton avec image.
    ---@param title string
    ---@param image string URL de l'image
    ---@param disabled boolean|nil
    ---@param callback fun()|nil
    ---@param submenu VUIMenu|nil
    ---@param index number|nil
    ---@return VUIItem
    menu.ImageButton = function(title, image, disabled, callback, submenu, index)
        return AddItem(menu.items, {
            type = "imagebutton",
            callback = callback,
            submenu = submenu,
            props = {
                title = title,
                image = image,
                disabled = disabled
            },
        }, index)
    end

    --- Ajoute un champ de recherche. Filtre automatiquement les items du menu.
    ---@param title string Placeholder du champ
    ---@param disabled boolean|nil
    ---@param index number|nil
    ---@return VUIItem
    menu.SearchInput = function(title, disabled, index)
        return AddItem(menu.items, {
            type = "searchinput",
            props = {
                title = title,
                disabled = disabled
            },
        }, index)
    end

    --- Ajoute une case à cocher.
    ---@param title string
    ---@param subtitle string|nil
    ---@param disabled boolean|nil
    ---@param checked boolean État initial
    ---@param callback fun(checked: boolean) Appelé à chaque changement d'état
    ---@param index number|nil
    ---@return VUIItem
    menu.Checkbox = function(title, subtitle, disabled, checked, callback, index)
        return AddItem(menu.items, {
            type = "checkbox",
            callback = callback,
            props = {
                title = title,
                subtitle = subtitle,
                disabled = disabled,
                checked = checked
            },
        }, index)
    end

    --- Ajoute une liste déroulante (clic = sélection + callback).
    ---@param title string
    ---@param subtitle string|nil
    ---@param disabled boolean|nil
    ---@param items string[] Valeurs de la liste
    ---@param index number Index initial (1-based)
    ---@param callback fun(index: number, value: string)|nil Appelé au clic (Entrée)
    ---@param submenu VUIMenu|nil
    ---@param _idx number|nil Position d'insertion
    ---@return VUIItem
    menu.List = function(title, subtitle, disabled, items, index, callback, submenu, _idx)
        return AddItem(menu.items, {
            type = "list",
            callback = callback,
            submenu = submenu,
            props = {
                title = title,
                subtitle = subtitle,
                disabled = disabled,
                items = items,
                index = index - 1
            },
        }, _idx)
    end

    --- Ajoute une liste avec deux callbacks distincts : flèches et Entrée.
    ---@param title string
    ---@param subtitle string|nil
    ---@param disabled boolean|nil
    ---@param items string[]
    ---@param index number Index initial (1-based)
    ---@param onArrow fun(index: number, value: string)|nil Déclenché sur ◀▶
    ---@param onEnter fun(index: number, value: string)|nil Déclenché sur Entrée
    ---@param _idx number|nil Position d'insertion
    ---@return VUIItem
    menu.List2 = function(title, subtitle, disabled, items, index, onArrow, onEnter, _idx)
        return AddItem(menu.items, {
            type = "list2",
            callback = onArrow,
            onEnter = onEnter,
            props = {
                title = title,
                subtitle = subtitle,
                disabled = disabled,
                items = items,
                index = index - 1
            },
        }, _idx)
    end

    --- Ajoute un slider numérique.
    ---@param title string
    ---@param value number Valeur initiale
    ---@param min number Valeur minimale
    ---@param max number Valeur maximale
    ---@param step number|nil Pas (défaut 1)
    ---@param subtitle string|nil
    ---@param disabled boolean|nil
    ---@param callback fun(value: number)|nil Appelé à chaque changement
    ---@param index number|nil
    ---@return VUIItem
    menu.Slider = function(title, value, min, max, step, subtitle, disabled, callback, index)
        return AddItem(menu.items, {
            type = "slider",
            callback = callback,
            props = {
                title = title,
                subtitle = subtitle,
                disabled = disabled,
                value = value,
                min = min,
                max = max,
                step = step or 1
            },
        }, index)
    end

    --- Ajoute un séparateur visuel (non-cliquable).
    ---@param leftLabel string|nil
    ---@param leftValue string|nil
    ---@param rightLabel string|nil
    ---@param rightValue string|nil
    ---@param index number|nil
    ---@return VUIItem
    menu.Separator = function(leftLabel, leftValue, rightLabel, rightValue, index)
        return AddItem(menu.items, {
            type = "separator",
            props = {
                leftLabel = leftLabel,
                leftValue = leftValue,
                rightLabel = rightLabel,
                rightValue = rightValue,
                disabled = true,
            },
        }, index)
    end

    --- Ajoute un bloc de texte (non-cliquable).
    ---@param content string Contenu texte
    ---@param title string|nil Titre optionnel
    ---@param index number|nil
    ---@return VUIItem
    menu.Textbox = function(content, title, index)
        return AddItem(menu.items, {
            type = "textbox",
            props = {
                content = content,
                title = title,
                disabled = true,
            },
        }, index)
    end

    --- Ajoute un bloc avec deux images (non-cliquable).
    ---@param image1 string URL image principale
    ---@param image2 string|nil URL image secondaire
    ---@param index number|nil
    ---@return VUIItem
    menu.Imagebox = function(image1, image2, index)
        return AddItem(menu.items, {
            type = "imagebox",
            props = {
                image1 = image1,
                image2 = image2,
                disabled = true,
            },
        }, index)
    end

    --- Ajoute un titre de section (non-cliquable).
    ---@param leftLabel string|nil
    ---@param leftValue string|nil
    ---@param rightLabel string|nil
    ---@param rightValue string|nil
    ---@param index number|nil
    ---@return VUIItem
    menu.Title = function(leftLabel, leftValue, rightLabel, rightValue, index)
        return AddItem(menu.items, {
            type = "title",
            props = {
                leftLabel = leftLabel,
                leftValue = leftValue,
                rightLabel = rightLabel,
                rightValue = rightValue,
                disabled = true,
            },
        }, index)
    end

    --- Récupère un item par index (number) ou par titre (string).
    ---@param key number|string Index 1-based ou titre exact
    ---@return VUIItem|nil
    menu.Get = function(key)
        -- if key is a number, return the item at that index
        if type(key) == "number" then
            return menu.items[key]
        end
        -- if key is a string, return the first item with that title
        if type(key) == "string" then
            for _, item in ipairs(menu.items) do
                if item.props.title == key then
                    return item
                end
            end
        end
    end

    menu.open = function()
        if menu.opened then
            if not VUI_HubMode then
                VUI_MenuStack = {}
            end
            VUI_IsExitingMenu = true
            menu.close()
            VUI_IsExitingMenu = false
            return
        end
        if VUI_CurrentMenu and VUI_CurrentMenu ~= menu and VUI_CurrentMenu.opened then
            if not VUI_HubMode then
                VUI_MenuStack = {}
            end
            VUI_Switching = true
            local ok, err = pcall(VUI_CurrentMenu.close)
            VUI_Switching = false
            if not ok then
                print("^1[VUI] Error closing previous menu: " .. tostring(err) .. "^7")
                VUI_CurrentMenu = nil
            end
        end
        VUI_CurrentMenu = menu
        VUI_CurrentMenu.opened = true

        -- Appel DIRECT : beaucoup d'OnOpen font TriggerServerCallback (Citizen.Await).
        -- pcall interdit le yield → le menu s'envoyait au NUI encore vide (rôles, items, etc.).
        if menu._openFn then
            menu._openFn()
        end

        -- Types that should always be shown (non-interactive / decorative)
        local alwaysShowTypes = {
            separator = true,
            textbox = true,
            imagebox = true,
            title = true
        }

        local _items = {}
        menu.visibleItems = {}
        for _, item in ipairs(menu.items) do
            table.insert(_items, {
                type = item.type,
                props = item.props
            })
            table.insert(menu.visibleItems, item)
        end

        local indexRestored = false
        if menu.title and VUI_LastMenuIndex[menu.title] and VUI_LastMenuIndex[menu.title] > 0 then
            menu.index = VUI_LastMenuIndex[menu.title]
            VUI_LastMenuIndex[menu.title] = nil
            indexRestored = true
        end

        -- Clamp restored index to valid range
        if menu.index > #_items then
            menu.index = math.max(1, #_items)
            indexRestored = false
        end

        -- Only skip separators if index was NOT restored (fresh open)
        if not indexRestored and #_items > 1 then
            menu.index = 1
            for i, item in ipairs(_items) do
                if not alwaysShowTypes[item.type] and not item.props.disabled then
                    break
                end
                menu.index = menu.index + 1
            end
            if menu.index > #_items then menu.index = #_items end
        end

        -- Cacher le chat quand le menu s'ouvre
        TriggerEvent('chat:setVisible', false)

        SendNUIMessage({
            action = "vui:menu",
            data = {
                title = menu.title,
                banner = menu.banner,
                index = menu.index - 1,
                helpButtons = menu._helpButtons,
                items = _items
            }
        })
    end

    -- Internal close: skips NUI message (used for submenu transitions)
    menu._closeInternal = function()
        menu.opened = false
        if menu._closeFn then
            local ok, err = pcall(menu._closeFn)
            if not ok then
                print("^1[VUI] Error in OnClose handler: " .. tostring(err) .. "^7")
            end
        end
        if menu.autoRefresh then
            menu.ClearItems()
        end
    end

    menu.close = function()
        SendNUIMessage({
            action = "vui:menu:close"
        })

        -- Fermer le menu courant s'il est différent de celui-ci
        if VUI_CurrentMenu and VUI_CurrentMenu ~= menu and VUI_CurrentMenu._closeInternal then
            VUI_CurrentMenu._closeInternal()
        end

        menu._closeInternal()

        -- Nettoyer tout le stack (marquer les parents comme fermés)
        if VUI_MenuStack then
            for i = #VUI_MenuStack, 1, -1 do
                local entry = VUI_MenuStack[i]
                local m = type(entry) == "table" and entry.menu or entry
                if m then m.opened = false end
            end
            VUI_MenuStack = {}
        end

        VUI_CurrentMenu = nil

        -- Mode hub : la chaîne de menus est terminée (pas un simple changement de menu)
        if VUI_HubMode and not VUI_Switching then
            VUI_HubMode = false
            VUI_HubReturnProxy = nil
            TriggerEvent("vui:hub:ended")
        end

        -- Après un court délai, vérifier si un menu est ouvert. Si non, montrer le chat.
        Citizen.SetTimeout(100, function()
            if not VUI_CurrentMenu then
                TriggerEvent('chat:setVisible', true)
            end
        end)
    end

    --- Rebuild le menu : sauvegarde l'index, ferme (flash NUI), puis rouvre.
    --- ⚠️ Cause un flash visuel. Toujours précéder d'un `if menu.opened then`.
    menu.refresh = function(resetIndex)
        if not resetIndex then
            VUI_LastMenuIndex[menu.title] = menu.index
        end
        local stack = VUI_MenuStack
        VUI_Switching = true
        menu.close()
        VUI_Switching = false
        VUI_MenuStack = stack
        menu.open()
    end

    menu.toggle = function()
        if menu.opened then
            menu.close()
        else
            menu.open()
        end
    end

    menu.isFiltered = function()
        return menu._isFiltered
    end

    menu.filter = function(filter)
        menu._isFiltered = true
        menu.index = 1
        menu.filterItems = {}
        local _items = {}

        for _, item in ipairs(menu.items) do
            if filter(item) then
                table.insert(_items, {
                    type = item.type,
                    props = item.props
                })
                table.insert(menu.filterItems, item)
            end
        end
        -- Re open the menu with the filtered items
        SendNUIMessage({
            action = "vui:menu",
            data = {
                title = menu.title,
                banner = menu.banner,
                index = menu.index - 1,
                items = _items
            }
        })
    end

    menu.removeFilter = function()
        menu._isFiltered = false
        menu.filterItems = {}

        local _items = {}
        menu.visibleItems = {}
        for _, item in ipairs(menu.items) do
            table.insert(_items, {
                type = item.type,
                props = item.props
            })
            table.insert(menu.visibleItems, item)
        end
        SendNUIMessage({
            action = "vui:menu",
            data = {
                title = menu.title,
                banner = menu.banner,
                index = menu.index - 1,
                items = _items
            }
        })
    end

    menu.ColorPicker = function(primaryR, primaryG, primaryB, secondaryR, secondaryG, secondaryB, onPrimaryChange, onSecondaryChange)
        VUI_ColorPickerCallbacks = {
            primary = onPrimaryChange,
            secondary = onSecondaryChange
        }
        SendNUIMessage({
            action = "vui:menu:colorPicker",
            data = {
                primary = { r = primaryR or 0, g = primaryG or 0, b = primaryB or 0 },
                secondary = { r = secondaryR or 0, g = secondaryG or 0, b = secondaryB or 0 }
            }
        })
        -- En mode hub le curseur appartient déjà à `core`. SetNuiFocus depuis VUI
        -- vole le focus vers le NUI VUI (invisible) et le picker du hub devient inerte.
        if not VUI_HubMode then
            SetNuiFocus(true, true)
            VUI_ColorPickerKeyThread = true
            CreateThread(function()
                while VUI_ColorPickerKeyThread do
                    Wait(0)
                    DisableControlAction(0, 200, true)
                    if IsDisabledControlJustPressed(0, 191) then
                        if VUI_CurrentMenu and VUI_CurrentMenu.CloseColorPicker then
                            VUI_CurrentMenu.CloseColorPicker()
                        end
                        break
                    end
                end
            end)
        end
    end

    menu.CloseColorPicker = function()
        VUI_ColorPickerKeyThread = false
        SendNUIMessage({ action = "vui:menu:closeColorPicker" })
        if VUI_HubMode then
            TriggerEvent("vui:hub:focus")
        else
            SetNuiFocus(false, false)
        end
        VUI_ColorPickerCallbacks = nil
    end

    menu.RoleColorPicker = function(r, g, b, title, onChange, onValidate, onCancel)
        VUI_RoleColorPickerCallbacks = {
            onChange = onChange,
            onValidate = onValidate,
            onCancel = onCancel,
            originalColor = { r = r or 255, g = g or 255, b = b or 255 },
            lastColor = { r = r or 255, g = g or 255, b = b or 255 }
        }
        SendNUIMessage({
            action = "vui:menu:roleColorPicker",
            data = {
                color = { r = r or 255, g = g or 255, b = b or 255 },
                title = title or "COULEUR DU ROLE"
            }
        })
        if not VUI_HubMode then
            SetNuiFocus(true, true)
            VUI_RoleColorPickerKeyThread = true
            CreateThread(function()
                while VUI_RoleColorPickerKeyThread do
                    Wait(0)
                    DisableControlAction(0, 200, true)
                    if IsDisabledControlJustPressed(0, 191) then
                        if VUI_RoleColorPickerCallbacks and VUI_RoleColorPickerCallbacks.onValidate then
                            local c = VUI_RoleColorPickerCallbacks.lastColor
                            VUI_RoleColorPickerCallbacks.onValidate(c.r, c.g, c.b)
                        end
                        if VUI_CurrentMenu and VUI_CurrentMenu.CloseRoleColorPicker then
                            VUI_CurrentMenu.CloseRoleColorPicker()
                        end
                        break
                    elseif IsDisabledControlJustPressed(0, 200) then
                        if VUI_RoleColorPickerCallbacks and VUI_RoleColorPickerCallbacks.onCancel then
                            VUI_RoleColorPickerCallbacks.onCancel()
                        end
                        if VUI_CurrentMenu and VUI_CurrentMenu.CloseRoleColorPicker then
                            VUI_CurrentMenu.CloseRoleColorPicker()
                        end
                        break
                    end
                end
            end)
        end
    end

    menu.CloseRoleColorPicker = function()
        VUI_RoleColorPickerKeyThread = false
        SendNUIMessage({ action = "vui:menu:closeRoleColorPicker" })
        if VUI_HubMode then
            TriggerEvent("vui:hub:focus")
        else
            SetNuiFocus(false, false)
        end
        VUI_RoleColorPickerCallbacks = nil
    end

    -- Case Preview for AFK shop
    menu.CasePreview = function(caseName, caseDescription, price, playerPoints, prizes, index)
        SendNUIMessage({
            action = "vui:menu:casePreview",
            data = {
                caseName = caseName,
                caseDescription = caseDescription,
                price = price,
                playerPoints = playerPoints,
                prizes = prizes
            }
        }, index)
    end

    menu.CloseCasePreview = function(index)
        SendNUIMessage({
            action = "vui:menu:closeCasePreview",
            data = { index = index }
        }, index)
    end

    -- VIP Preview
    menu.VipPreview = function(tierLabel, tierColor, spacecoins, advantages)
        SendNUIMessage({
            action = "vui:menu:vipPreview",
            data = {
                tierLabel = tierLabel,
                tierColor = tierColor,
                spacecoins = spacecoins,
                advantages = advantages
            }
        })
    end

    menu.CloseVipPreview = function()
        SendNUIMessage({
            action = "vui:menu:closeVipPreview"
        })
    end

    -- Enregistre le menu (clé faible) pour réappliquer la bannière de marque à chaud.
    -- Clé = menu lui-même : pas de croissance non bornée (dédoublonné) et collecte
    -- automatique par le GC dès que le menu n'est plus référencé ailleurs.
    VUI_AllMenus[menu] = true

    return menu
end

--- Crée un sous-menu lié à un menu parent.
--- Le parent est automatiquement accessible via le bouton retour.
---@param parent VUIMenu Menu parent
---@param title string Titre du sous-menu
---@param banner string URL du banner
---@param autoRefresh boolean|nil Si true, ClearItems() à chaque fermeture
---@return VUIMenu
function CreateSubMenu(parent, title, banner, autoRefresh)
    local menu = CreateMenu(title, banner, autoRefresh)
    menu.parent = parent
    return menu
end

--- Affiche ou masque une alerte staff dans le NUI.
---@param name string Nom de l'alerte
---@param permission string Permission requise
---@param message string Message à afficher
function ToggleStaffAlert(name, permission, message)
    SendNUIMessage({
        action = "vui:staffAlert",
        data = {
            name = name,
            permission = permission,
            message = message
        }
    })
end

VUI_SoundEnabled = true

---@param enabled boolean
function SetSoundEnabled(enabled)
    VUI_SoundEnabled = enabled
    SendNUIMessage({
        action = "vui:sound:toggle",
        data = { enabled = enabled }
    })
end

--- Ouvre un menu en plaçant un "retour" personnalisé dans la pile de navigation :
--- quand l'utilisateur fait retour arrière depuis ce menu (ou depuis ses sous-menus
--- jusqu'à lui), `returnFn` est appelé à la place de l'ouverture du menu parent.
--- Utilisé par le hub de gestion NUI de `core` pour revenir au hub après un outil VUI.
---@param openFn fun() Fonction d'ouverture du menu (menu.open)
---@param returnFn fun() Appelée au retour arrière
--- Fonction locale OU référence de fonction d'une autre ressource (table appelable).
---@param f any
---@return boolean
local function IsCallable(f)
    if type(f) == "function" then return true end
    if type(f) == "table" then
        local mt = getmetatable(f)
        return mt ~= nil and mt.__call ~= nil
    end
    return false
end

function OpenWithReturn(openFn, returnFn)
    if not IsCallable(openFn) then return end

    local proxy = { title = "__return__", opened = false, items = {}, index = 1, _helpButtons = {} }
    proxy.open = function()
        -- Le menu qui faisait retour a déjà été fermé en interne (sans message NUI) :
        -- on ferme l'affichage puis on rend la main à l'appelant.
        SendNUIMessage({ action = "vui:menu:close" })
        VUI_MenuStack = {}
        VUI_CurrentMenu = nil
        VUI_HubMode = false
        VUI_HubReturnProxy = nil
        if IsCallable(returnFn) then
            local ok, err = pcall(returnFn)
            if not ok then
                print("^1[VUI] Error in OpenWithReturn return handler: " .. tostring(err) .. "^7")
            end
        end
    end
    proxy.close = function()
        VUI_CurrentMenu = nil
    end
    proxy._closeInternal = proxy.close

    if VUI_HubMode then
        VUI_HubReturnProxy = proxy
    end

    openFn()
    -- Placé APRÈS l'ouverture : menu.open() vide la pile s'il ferme un menu précédent.
    if VUI_CurrentMenu then
        VUI_MenuStack = { { menu = proxy, savedIndex = 1 } }
    end
end

--- Comme OpenWithReturn, mais le menu (et ses sous-menus) sont rendus par le hub de
--- gestion de `core` : voir VUI_HubMode.
---@param openFn fun()
---@param returnFn fun()
function OpenInHub(openFn, returnFn)
    VUI_HubMode = true
    -- Le overlay VUI (menu F5) ne doit jamais rester affiché : le hub de `core` rend à sa place.
    _SendNUIMessageNative({ action = "vui:menu:close" })
    OpenWithReturn(openFn, returnFn)
    if not VUI_CurrentMenu then
        -- Le menu ne s'est pas ouvert : on rend le mode hub cohérent
        VUI_HubMode = false
        VUI_HubReturnProxy = nil
        TriggerEvent("vui:hub:ended")
    end
end

--- Le hub de gestion est-il en train de rendre un menu VUI ?
---@return boolean
function IsHubMode()
    return VUI_HubMode == true
end

exports("HandleBack", VUI_HandleBack)
exports("OpenWithReturn", OpenWithReturn)
exports("OpenInHub", OpenInHub)
exports("IsHubMode", IsHubMode)
exports("CreateMenu", CreateMenu)
exports("CreateSubMenu", CreateSubMenu)
exports("ToggleStaffAlert", ToggleStaffAlert)
exports("SetSoundEnabled", SetSoundEnabled)
exports("GetMenuPosition", GetMenuPosition)
exports("SetMenuPosition", SetMenuPosition)
exports("GetMenuOffset", GetMenuOffset)
exports("SetMenuOffset", SetMenuOffset)
exports("GetPreviewOffset", GetPreviewOffset)
exports("SetPreviewOffset", SetPreviewOffset)
exports("SetMenuOrientation", SetMenuOrientation)
exports("GetMaxItems", GetMaxItems)
exports("SetMaxItems", SetMaxItems)

-- Mode dev des interfaces (core : /uidev <url> | off, /uireload) : la page des menus
-- bascule sur le serveur Vite (rechargement à chaud) ou revient au build.
AddEventHandler('core:uidev', function(url)
    SendNUIMessage({ action = 'vui:dev', data = { url = type(url) == 'string' and url or '' } })
end)
AddEventHandler('core:uireload', function()
    SendNUIMessage({ action = 'vui:reload' })
end)
