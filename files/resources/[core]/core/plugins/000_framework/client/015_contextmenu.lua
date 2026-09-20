---@meta _
---@diagnostic disable: duplicate-doc-field

local ENTITY_TYPES_LIST <const> = {
    ['world'] = 0,
    ['ped'] = 1,
    ['vehicle'] = 2,
    ['object'] = 3,
    ['position'] = 4 -- Virtual type for position-based entries
}

local lastsEntity
local lastsEntityNetId = 0
local lastsEntityType = 0
local lastWorldPosition
local lastMatchedPosition = nil

local suscribedButtonsNumber = 0
local suscribedButtons = {}

-- Index: entityType -> { [i] = buttonId }
local buttonsByEntityType = {
    [0] = {}, -- world
    [1] = {}, -- ped
    [2] = {}, -- vehicle
    [3] = {}, -- object
}

-- Index: submenuId -> { [i] = buttonId }
local buttonsBySubmenu = {}

-- Modèles exclus par type d'entité : ces modèles ne montrent aucun bouton du type concerné
-- sauf ceux explicitement marqués ignoreExclusion = true dans opts
local excludedModels = {
    [2] = {}, -- vehicle
    [3] = {}, -- object
}

local function indexButton(id, btn)
    -- Index par entitytype
    if btn.entitytype then
        local et = ENTITY_TYPES_LIST[btn.entitytype]
        if et and buttonsByEntityType[et] then
            buttonsByEntityType[et][#buttonsByEntityType[et] + 1] = id
        end
    end
    -- Index par submenu parent
    local parent = btn.submenu or 0 -- 0 = root
    if not buttonsBySubmenu[parent] then
        buttonsBySubmenu[parent] = {}
    end
    buttonsBySubmenu[parent][#buttonsBySubmenu[parent] + 1] = id
end

local function unindexButton(id)
    local btn = suscribedButtons[id]
    if not btn then return end
    -- Retirer de l'index entitytype
    if btn.entitytype then
        local et = ENTITY_TYPES_LIST[btn.entitytype]
        if et and buttonsByEntityType[et] then
            local list = buttonsByEntityType[et]
            for i = #list, 1, -1 do
                if list[i] == id then
                    table.remove(list, i)
                    break
                end
            end
        end
    end
    -- Retirer de l'index submenu
    local parent = btn.submenu or 0
    if buttonsBySubmenu[parent] then
        local list = buttonsBySubmenu[parent]
        for i = #list, 1, -1 do
            if list[i] == id then
                table.remove(list, i)
                break
            end
        end
    end
end

-- Position-based context menu registry
local suscribedPositionsNumber = 0
local suscribedPositions = {} -- { id = { position = vec3, radius = number, buttons = {} } }

local mouseActive = false
local contextMenuHasFocus = false
-- Snapshot of VFW.Nui._hasCursor BEFORE openContextMenu stole the cursor.
-- closeContextMenu uses this to decide whether to release the cursor: if some
-- other UI already had it before us, leave it alone; otherwise release it.
local prevHadCursor = false
-- Generation counter: each open() bumps it so a stale raycast thread from a
-- previous session exits on its next iteration if a new session has started.
local threadGen = 0

-- Forward declarations for open/close lifecycle (idempotent)
local openContextMenu
local closeContextMenu

-- Forward declarations for position-based functions
local FindMatchingPosition
local HasAnyPositionEntry

-- Lier un scope à un sous-menu : VFW.ContextBindScope(submenuId, "vehicle:police")
function VFW.ContextBindScope(submenuId, scopeName)
    local b = suscribedButtons[submenuId]
    if b and b.isSubmenu then
        b.scopeName = scopeName
    end
end

--- Exclure un modèle d'entité du context menu (tous les boutons de ce type seront masqués sauf ignoreExclusion)
---@param entityType string "vehicle"|"object"
---@param model string|number Nom du modèle ou hash
function VFW.ContextExcludeModel(entityType, model)
    local typeId = ENTITY_TYPES_LIST[entityType]
    if typeId and excludedModels[typeId] then
        excludedModels[typeId][type(model) == "number" and model or GetHashKey(model)] = true
    end
end

local function condOk(btn, ent, scope)
    -- Check permission first if defined
    if btn.permission then
        if not VFW.HasStaffPerm(btn.permission) then
            return false
        end
    end

    -- Check model exclusion
    if not btn.ignoreExclusion and ent and btn.entitytype then
        local typeId = ENTITY_TYPES_LIST[btn.entitytype]
        if typeId and excludedModels[typeId] and DoesEntityExist(ent) then
            if excludedModels[typeId][GetEntityModel(ent)] then
                return false
            end
        end
    end

    if btn.condition == nil then
        return true
    end
    local t = type(btn.condition)
    if t == "function" or t == "table" then
        local ok, result = pcall(btn.condition, ent, scope)
        if not ok then
            return false
        end
        return result
    end
    if t == "boolean" then
        return btn.condition
    end
    return false
end

local function computeValue(v, ent, scope)
    if v == nil then
        return nil
    end
    local t = type(v)
    if t == "function" or t == "table" then
        local ok, result = pcall(v, ent, scope)
        if ok then return result end
        return nil
    end
    return v
end

-- résolution scope côté serveur pour un sous-menu donné
local function ResolveScopeForSubmenu(submenuId, ENTITY, ENTITY_TYPE, WORLD_POSITION)
    local btn = suscribedButtons[submenuId]
    if not btn or not btn.isSubmenu or not btn.scopeName then
        return nil, nil
    end

    local netId = (ENTITY ~= 0) and NetworkGetEntityIsNetworked(ENTITY) and NetworkGetNetworkIdFromEntity(ENTITY) or 0
    local wx, wy, wz = nil, nil, nil
    if WORLD_POSITION then
        wx, wy, wz = WORLD_POSITION.x, WORLD_POSITION.y, WORLD_POSITION.z
    end

    local resp = TriggerServerCallback("vfw:scope:resolve", btn.scopeName, netId, (ENTITY_TYPE or 0), wx, wy, wz)

    -- Attendu côté serveur:
    -- { ok=true, scope={...}, source=<openerSrc>, netId=<targetNetId>, entType=<0..3>, world={x=..,y=..,z=..} }
    if resp and resp.ok and resp.scope then
        resp.scope._source = resp.source         -- joueur qui ouvre le menu (server id)
        resp.scope._netId = resp.netId          -- entité ciblée
        resp.scope._entType = resp.entType        -- type entity (0..3)
        resp.scope._world = resp.world          -- coords si dispo
        return resp.scope, btn.scopeName
    end

    return nil, btn.scopeName
end

-- batch conditions serveur pour une liste d'ids enfants
local function EvaluateServerConditions(childIds, ENTITY, ENTITY_TYPE, WORLD_POSITION, scope, scopeName)
    local items = {}
    local hasAny = false
    for _, id in ipairs(childIds) do
        local b = suscribedButtons[id]
        if b and b.serverCondition then
            table.insert(items, { id = id, route = b.serverCondition })
            hasAny = true
        end
    end
    if not hasAny then
        return nil
    end

    local netId = (ENTITY ~= 0) and NetworkGetEntityIsNetworked(ENTITY) and NetworkGetNetworkIdFromEntity(ENTITY) or 0
    local world = WORLD_POSITION and { x = WORLD_POSITION.x, y = WORLD_POSITION.y, z = WORLD_POSITION.z } or nil

    -- Renvoie un map { ["<id>"]=true|false }
    local results = TriggerServerCallback("vfw:conds:batch", {
        ent = { netId = netId, entType = ENTITY_TYPE or 0, world = world },
        items = items,
        scopeName = scopeName,
        scope = scope
    })
    return results
end

--- Trie une liste d'IDs en intercalant les boutons avec order aux positions absolues
--- et en remplissant les trous avec ceux sans order (dans leur ordre d'insertion)
---@param ids number[]
---@return number[]
local function sortByAbsoluteOrder(ids)
    local withOrder = {}
    local withoutOrder = {}
    for _, id in ipairs(ids) do
        local btn = suscribedButtons[id]
        if btn and btn.order then
            withOrder[#withOrder + 1] = id
        else
            withoutOrder[#withoutOrder + 1] = id
        end
    end

    -- Si aucun order défini, garder l'ordre d'insertion (par id croissant)
    if #withOrder == 0 then
        table.sort(withoutOrder)
        return withoutOrder
    end

    -- Trier les withOrder par leur valeur order
    table.sort(withOrder, function(a, b)
        return suscribedButtons[a].order < suscribedButtons[b].order
    end)
    -- Trier les withoutOrder par id (ordre d'insertion)
    table.sort(withoutOrder)

    -- Construire la liste finale en intercalant
    local result = {}
    local woIdx = 1 -- index dans withoutOrder

    -- Placer chaque bouton avec order à sa position absolue,
    -- remplir avant avec des sans-order
    for _, id in ipairs(withOrder) do
        local targetPos = suscribedButtons[id].order
        -- Remplir les positions avant avec des sans-order
        while #result < targetPos - 1 and woIdx <= #withoutOrder do
            result[#result + 1] = withoutOrder[woIdx]
            woIdx = woIdx + 1
        end
        result[#result + 1] = id
    end

    -- Ajouter les sans-order restants à la fin
    while woIdx <= #withoutOrder do
        result[#result + 1] = withoutOrder[woIdx]
        woIdx = woIdx + 1
    end

    return result
end

local function SendHoverIndicator(show, x, y)
    SendNUIMessage({
        action = "nui:hover-indicator",
        type = "nui:hover-indicator",
        data = { show = show, x = x, y = y }
    })
end

local function HasAnyChild(buttonId, ENTITY, ENTITY_TYPE)
    local children = buttonsBySubmenu[buttonId]
    if not children then return false end
    for i = 1, #children do
        local id = children[i]
        local b = suscribedButtons[id]
        if b then
            local okEntity = ((b.entitytype and (ENTITY_TYPES_LIST[b.entitytype] == ENTITY_TYPE)) or
                    (ENTITY ~= 0 and b.entity and (ENTITY == b.entity)))
            if okEntity and condOk(b, ENTITY, nil) then
                return true
            end
            if b.isSubmenu then
                if HasAnyChild(id, ENTITY, ENTITY_TYPE) then
                    return true
                end
            end
        end
    end
    return false
end

local function HasAnyEntryForEntity(ENTITY, ENTITY_TYPE)
    -- Parcourir les boutons root du bon entityType via l'index
    local rootIds = buttonsBySubmenu[0]
    if not rootIds then return false end
    for i = 1, #rootIds do
        local id = rootIds[i]
        local b = suscribedButtons[id]
        if b then
            local okEntity = ((b.entitytype and (ENTITY_TYPES_LIST[b.entitytype] == ENTITY_TYPE)) or
                    (ENTITY ~= 0 and b.entity and (ENTITY == b.entity)))
            if okEntity and condOk(b, ENTITY, nil) then
                if b.isSubmenu then
                    if HasAnyChild(id, ENTITY, ENTITY_TYPE) then
                        return true
                    end
                else
                    return true
                end
            end
        end
    end
    return false
end

--- Cherche un ped joueur attache au ped local (escorte) a proximite du curseur
---@param worldPos vector3
---@param radius number
---@return number|nil pedHandle
local function FindNearbyAttachedPed(worldPos, radius)
    local myPed = PlayerPedId()
    local closest = nil
    local closestDist = radius
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            if ped ~= 0 and DoesEntityExist(ped) and IsEntityAttachedToEntity(ped, myPed) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(worldPos - pedCoords)
                if dist < closestDist then
                    closestDist = dist
                    closest = ped
                end
            end
        end
    end
    return closest
end

--- Cherche un ped mort/dans le coma a proximite d'une position (fallback raycast)
---@param worldPos vector3
---@param radius number
---@return number|nil pedHandle
local function FindNearbyDeadPed(worldPos, radius)
    local closest = nil
    local closestDist = radius
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local ped = GetPlayerPed(playerId)
            if ped ~= 0 and DoesEntityExist(ped) and IsPedDeadOrDying(ped, true) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(worldPos - pedCoords)
                if dist < closestDist then
                    closestDist = dist
                    closest = ped
                end
            end
        end
    end
    return closest
end

-- Re-assert NUI focus + cursor + visible state for the context menu. Used by
-- both openContextMenu (initial open on ALT) and ContextMenuButtonClick (after
-- a button action which may have stolen the cursor or the focus).
-- IMPORTANT: install _onExternalFocus AFTER calling SetNuiFocus, since the
-- wrapped SetNuiFocus in 010_nui.lua fires _onExternalFocus on hasFocus=true,
-- which would self-trigger closeContextMenu otherwise.
local function applyContextFocus()
    SendNUIMessage({
        action = "nui:context-menu:visible",
        data = true,
    })

    VFW.Nui._onExternalFocus = nil
    SetNuiFocusKeepInput(true)
    SetNuiFocus(true, true)

    VFW.Nui._onExternalFocus = function()
        closeContextMenu()
    end
end

-- Open the context menu (idempotent). Lifecycle owner: ALT key.
openContextMenu = function()
    if mouseActive then return end
    mouseActive = true
    contextMenuHasFocus = true
    threadGen = threadGen + 1
    local myGen = threadGen

    -- Capture cursor state BEFORE we steal it, so close() can restore it.
    prevHadCursor = VFW.Nui._hasCursor == true

    applyContextFocus()
    SetCursorLocation(0.5, 0.5)

    CreateThread(function()
        local ringShown = false
        local lastSend = 0
        local lastX, lastY = -1, -1

        while mouseActive and threadGen == myGen do
            -- Désactiver complètement le mouvement caméra (souris)
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisablePlayerFiring(PlayerId(), true)

            local now = GetGameTimer()
            if now - lastSend >= 50 then
                lastSend = now

                local x, y = GetNuiCursorPosition()
                local SCRX, SCRY = GetActiveScreenResolution()
                local nx, ny = x / SCRX, y / SCRY

                -- Don't ignore PlayerPedId() to allow clicking on yourself
                local HIT, WORLD_POSITION, NORMAL_DIRECTION, ENTITY = RaycastScreen(vector2(nx, ny), 300.0, -1)
                ENTITY = ENTITY or 0

                local show = false
                if HIT then
                    -- Fallback: si le ray touche le sol, chercher un ped mort a proximite
                    if (ENTITY == 0 or GetEntityType(ENTITY) == 0) and WORLD_POSITION then
                        local deadPed = FindNearbyDeadPed(WORLD_POSITION, 1.0)
                        if deadPed then
                            ENTITY = deadPed
                        end
                    end

                    -- Fallback: si le ray touche le sol ou soi-meme, chercher un ped attache (escorte)
                    if WORLD_POSITION and (ENTITY == 0 or GetEntityType(ENTITY) == 0 or ENTITY == PlayerPedId()) then
                        local attachedPed = FindNearbyAttachedPed(WORLD_POSITION, 2.0)
                        if attachedPed then
                            ENTITY = attachedPed
                        end
                    end

                    -- Check entity-based entries
                    if ENTITY ~= 0 then
                        local ENTITY_TYPE = GetEntityType(ENTITY) or 0
                        -- pas le sol => on ignore world (0)
                        if ENTITY_TYPE ~= 0 then
                            show = HasAnyEntryForEntity(ENTITY, ENTITY_TYPE)
                        end
                    end

                    -- Check position-based entries if no entity match
                    if not show and WORLD_POSITION then
                        show = HasAnyPositionEntry(WORLD_POSITION)
                    end
                end

                if show ~= ringShown or x ~= lastX or y ~= lastY then
                    ringShown = show
                    lastX, lastY = x, y
                    -- Send normalized coordinates instead of raw pixels
                    SendHoverIndicator(show, nx, ny)
                end
            end

            Wait(0)
        end

        -- Only the current generation's thread should hide the eye on exit.
        -- A stale thread exiting must not stomp on a fresh session.
        if threadGen == myGen then
            SendHoverIndicator(false)
        end
    end)
end

-- Close the context menu (idempotent).
closeContextMenu = function()
    if not mouseActive then return end
    mouseActive = false
    contextMenuHasFocus = false
    VFW.Nui._onExternalFocus = nil

    SendNUIMessage({
        action = "nui:context-menu:visible",
        data = false,
    })
    SetNuiFocusKeepInput(false)
    -- Only release the cursor if no other UI had it before we opened.
    -- (_hasCursor is currently true because WE set it on open; it cannot be
    -- used as a guard here.)
    if not prevHadCursor then
        SetNuiFocus(false, false)
    end
    DisablePlayerFiring(PlayerId(), false)
    SendHoverIndicator(false)
end

--- .OpenContextMenu - public toggle (back-compat: many callers use this to close).
function VFW.OpenContextMenu()
    if mouseActive then
        closeContextMenu()
    else
        openContextMenu()
    end
end

VFW.KeybindToggle("LMENU", "openContext", "Context menu", function()
    if mouseActive then return end
    -- Only block if cursor is visible (not just keyboard focus)
    if VFW.Nui._hasCursor then return end
    openContextMenu()
end, function()
    closeContextMenu()
end)

RegisterNUICallback("ContextMenuPosition", function(data, cb)
    -- data.x and data.y are already normalized (0-1)
    local X <const>, Y <const> = data.x, data.y

    -- Don't ignore PlayerPedId() to allow clicking on yourself
    local HIT, WORLD_POSITION, NORMAL_DIRECTION, ENTITY = RaycastScreen(vector2(X, Y), 300.0, -1)
    ENTITY = ENTITY or 0
    if HIT then
        -- Fallback: si le ray touche le sol, chercher un ped mort a proximite
        if (ENTITY == 0 or GetEntityType(ENTITY) == 0) and WORLD_POSITION then
            local deadPed = FindNearbyDeadPed(WORLD_POSITION, 1.0)
            if deadPed then
                ENTITY = deadPed
            end
        end

        -- Fallback: si le ray touche le sol ou soi-meme, chercher un ped attache (escorte)
        if WORLD_POSITION and (ENTITY == 0 or GetEntityType(ENTITY) == 0 or ENTITY == PlayerPedId()) then
            local attachedPed = FindNearbyAttachedPed(WORLD_POSITION, 2.0)
            if attachedPed then
                ENTITY = attachedPed
            end
        end

        lastsEntity = ENTITY
        lastsEntityType = GetEntityType(ENTITY) or 0
        lastsEntityNetId = (ENTITY ~= 0 and NetworkGetEntityIsNetworked(ENTITY)) and NetworkGetNetworkIdFromEntity(ENTITY) or 0
        lastWorldPosition = WORLD_POSITION
        lastMatchedPosition = nil
        local ENTITY_TYPE <const> = lastsEntityType

        local buttonList = {}
        local function matchEntity(button)
            return ((button.entitytype and (ENTITY_TYPES_LIST[button.entitytype] == ENTITY_TYPE))
                    or (ENTITY ~= 0 and button.entity and (ENTITY == button.entity)))
        end

        --- AddChilds : construit dynamiquement un sous-menu (hover) avec scope + batch conditions serveur
        ---@param buttonId number|string
        local function AddChilds(buttonId)
            local scope, scopeName = ResolveScopeForSubmenu(buttonId, ENTITY, ENTITY_TYPE, WORLD_POSITION)

            local childIds = {}
            local indexed = buttonsBySubmenu[buttonId]
            if indexed then
                for i = 1, #indexed do
                    local id = indexed[i]
                    local button = suscribedButtons[id]
                    if button and matchEntity(button) then
                        childIds[#childIds + 1] = id
                    end
                end
            end

            childIds = sortByAbsoluteOrder(childIds)

            local serverRes = EvaluateServerConditions(childIds, ENTITY, ENTITY_TYPE, WORLD_POSITION, scope, scopeName)

            local childList = {}
            for _, id in ipairs(childIds) do
                local button = suscribedButtons[id]
                if button then
                    if button.serverCondition then
                        local okSrv = serverRes and (serverRes[tostring(id)] == true)
                        if not okSrv then
                            goto continue_child
                        end
                    end
                    if not condOk(button, ENTITY, (button.useScope and scope or nil)) then
                        goto continue_child
                    end
                    local entry = {
                        id = id,
                        name = button.name,
                        style = button.style,
                        value = computeValue(button.value, ENTITY, (button.useScope and scope or nil))
                    }
                    if button.isSubmenu then
                        entry.child = AddChilds(id)
                        if not entry.child or #entry.child == 0 then
                            goto continue_child
                        end
                        entry.scrollable = button.scrollable
                    end
                    childList[#childList + 1] = entry
                end
                :: continue_child ::
            end
            return childList
        end

        local rootIds = {}
        local rootIndexed = buttonsBySubmenu[0]
        if rootIndexed then
            for i = 1, #rootIndexed do
                local id = rootIndexed[i]
                local button = suscribedButtons[id]
                if button and matchEntity(button) then
                    rootIds[#rootIds + 1] = id
                end
            end
        end

        rootIds = sortByAbsoluteOrder(rootIds)

        local rootServerRes = EvaluateServerConditions(rootIds, ENTITY, ENTITY_TYPE, WORLD_POSITION, nil, nil)

        for _, id in ipairs(rootIds) do
            local button = suscribedButtons[id]
            if button then
                if button.serverCondition then
                    local okSrv = rootServerRes and (rootServerRes[tostring(id)] == true)
                    if not okSrv then
                        goto continue_root
                    end
                end
                if not condOk(button, ENTITY, nil) then
                    goto continue_root
                end
                local entry = {
                    id = id,
                    name = button.name,
                    style = button.style,
                    value = computeValue(button.value, ENTITY, nil)
                }
                if button.isSubmenu then
                    entry.child = AddChilds(id)
                    if not entry.child or #entry.child == 0 then
                        goto continue_root
                    end
                    entry.scrollable = button.scrollable
                end
                buttonList[#buttonList + 1] = entry
            end
            :: continue_root ::
        end

        -- ============================================
        -- POSITION-BASED ENTRIES
        -- ============================================
        if WORLD_POSITION then
            local posId, posData = FindMatchingPosition(WORLD_POSITION)
            if posId and posData then
                lastMatchedPosition = { id = posId, data = posData }

                --- AddPositionChilds: build position-based submenu children
                ---@param parentBtnId number
                local function AddPositionChilds(parentBtnId)
                    local childList = {}
                    for btnId, btn in pairs(posData.buttons) do
                        if btn.submenu == parentBtnId then
                            if condOk(btn, 0, nil) then
                                local entry = {
                                    id = "pos_" .. posId .. "_" .. btnId,
                                    name = btn.name,
                                    style = btn.style,
                                    value = computeValue(btn.value, 0, nil)
                                }
                                if btn.isSubmenu then
                                    entry.child = AddPositionChilds(btnId)
                                end
                                childList[#childList + 1] = entry
                            end
                        end
                    end
                    return childList
                end

                -- Add root-level position buttons
                for btnId, btn in pairs(posData.buttons) do
                    if not btn.submenu then
                        -- Root level only
                        if condOk(btn, 0, nil) then
                            local entry = {
                                id = "pos_" .. posId .. "_" .. btnId,
                                name = btn.name,
                                style = btn.style,
                                value = computeValue(btn.value, 0, nil)
                            }
                            if btn.isSubmenu then
                                entry.child = AddPositionChilds(btnId)
                            end
                            buttonList[#buttonList + 1] = entry
                        end
                    end
                end
            end
        end

        if #buttonList == 0 then
            return
        end

        cb(buttonList)
        return
    end
end)

RegisterNUICallback("ContextMenuClose", function(_, cb)
    -- Legacy bundle compat: the pre-rebuild React calls this on every window
    -- click and sets visible=false locally, expecting the Lua side to re-show
    -- the menu if ALT is still held. New React doesn't call this at all.
    -- Re-broadcast visible=true if the context is still active so the legacy
    -- bundle can recover its visible state and accept further right-clicks.
    if mouseActive then
        SendNUIMessage({
            action = "nui:context-menu:visible",
            data = true,
        })
    end
    if cb then cb({}) end
end)

RegisterNUICallback("ContextMenuInfoCopy", function(data, cb)
    local btn = suscribedButtons[data.id]
    local label = (btn and btn.name) or "Valeur"
    VFW.ShowNotification({
        type = 'INFO', variant = 'INFO', subtitle = 'Presse-papier',
        message = label .. " copié."
    })
    if cb then cb({}) end
end)

RegisterNUICallback("ContextMenuButtonClick", function(data)
    -- Run the user-supplied action first. The callback can do anything,
    -- including stealing NUI focus (open another UI) or releasing the cursor
    -- via SetNuiFocus(false, false). After it returns, if ALT is still held
    -- (mouseActive == true) we re-assert the context menu focus exactly like
    -- the ALT-press path so the system cursor + right-click stay alive.
    local function runAction()
        local idStr = tostring(data.id)

        -- Position-based button (format: "pos_<posId>_<btnId>")
        if idStr:sub(1, 4) == "pos_" then
            local parts = {}
            for part in idStr:gmatch("[^_]+") do
                table.insert(parts, part)
            end
            if #parts >= 3 then
                local posId = tonumber(parts[2])
                local btnId = tonumber(parts[3])

                if posId and btnId then
                    local posData = suscribedPositions[posId]
                    if posData and posData.buttons[btnId] then
                        local btn = posData.buttons[btnId]
                        if not btn.isSubmenu and btn.callback then
                            btn.callback(lastWorldPosition, posData.position)
                        end
                    end
                end
            end
            return
        end

        -- Regular entity-based button handling
        local btn = suscribedButtons[data.id]
        if not btn or btn.isSubmenu then
            return
        end

        local ENTITY = lastsEntity or 0
        local ENTITY_TYPE = lastsEntityType or 0
        local netId = lastsEntityNetId or 0
        local world = lastWorldPosition and { x = lastWorldPosition.x, y = lastWorldPosition.y, z = lastWorldPosition.z } or nil

        local scope, scopeName = nil, nil
        if btn.submenu then
            scope, scopeName = ResolveScopeForSubmenu(btn.submenu, ENTITY, ENTITY_TYPE, lastWorldPosition)
        end

        if btn.serverAction then
            local res = TriggerServerCallback("vfw:action:run", {
                action = btn.serverAction,
                ent = { netId = netId, entType = ENTITY_TYPE, world = world },
                scopeName = scopeName,
                scope = scope,
                extra = btn.extra,
                permission = btn.permission
            })
            if res and res.ok then
                SendNUIMessage({ action = "nui:toast", data = { ok = true, msg = res.msg or "OK" } })
            else
                SendNUIMessage({ action = "nui:toast", data = { ok = false, msg = (res and (res.err or res.msg)) or "Erreur" } })
            end
            return
        end

        suscribedButtons[data.id].callback(lastsEntity, lastWorldPosition, ENTITY_TYPE, scope)
    end

    pcall(runAction)

    -- If ALT is still held and no callback explicitly closed the context menu,
    -- replay the ALT-press setup so cursor + right-click stay functional.
    if mouseActive then
        applyContextFocus()
    end
end)

--- .ContextAddSubmenu
---@param entity any
---@param name string
---@param condition any
---@param style any
---@param submenu any
---@param opts table|nil -- { serverCondition=string, useScope=bool, order=number, permission=string }
function VFW.ContextAddSubmenu(entity, name, condition, style, submenu, opts)
    if type(entity) == 'string' then
        assert(entity == 'ped' or entity == 'vehicle' or entity == 'object' or entity == 'world',
                'Invalid entity type (ped, vehicle, object, world)')
    end

    suscribedButtonsNumber = suscribedButtonsNumber + 1

    suscribedButtons[suscribedButtonsNumber] = {
        name = name,
        condition = condition,
        style = style or {},
        submenu = submenu,
        isSubmenu = true
    }

    if opts then
        suscribedButtons[suscribedButtonsNumber].serverCondition = opts.serverCondition
        suscribedButtons[suscribedButtonsNumber].useScope = opts.useScope
        suscribedButtons[suscribedButtonsNumber].order = opts.order
        suscribedButtons[suscribedButtonsNumber].permission = opts.permission
        suscribedButtons[suscribedButtonsNumber].scrollable = opts.scrollable
        suscribedButtons[suscribedButtonsNumber].ignoreExclusion = opts.ignoreExclusion
    end

    if type(entity) == 'string' then
        suscribedButtons[suscribedButtonsNumber].entitytype = entity
    else
        suscribedButtons[suscribedButtonsNumber].entity = entity
    end

    indexButton(suscribedButtonsNumber, suscribedButtons[suscribedButtonsNumber])
    return suscribedButtonsNumber
end

--- .ContextAddButton
---@param entity any
---@param name string
---@param condition any
---@param callback function Callback function
---@param style any
---@param submenu any
---@param opts table|nil -- { serverCondition=string, serverAction=string, useScope=bool, order=number, permission=string }
function VFW.ContextAddButton(entity, name, condition, callback, style, submenu, opts)
    if type(entity) == 'string' then
        assert(entity == 'ped' or entity == 'vehicle' or entity == 'object' or entity == 'world',
                'Invalid entity type (ped, vehicle, object, world)')
    end

    suscribedButtonsNumber = suscribedButtonsNumber + 1

    suscribedButtons[suscribedButtonsNumber] = {
        name = name,
        condition = condition,
        callback = callback,
        style = style or {},
        submenu = submenu
    }

    if opts then
        suscribedButtons[suscribedButtonsNumber].serverCondition = opts.serverCondition
        suscribedButtons[suscribedButtonsNumber].serverAction = opts.serverAction
        suscribedButtons[suscribedButtonsNumber].useScope = opts.useScope
        suscribedButtons[suscribedButtonsNumber].order = opts.order
        suscribedButtons[suscribedButtonsNumber].permission = opts.permission
        suscribedButtons[suscribedButtonsNumber].extra = opts.extra
        suscribedButtons[suscribedButtonsNumber].ignoreExclusion = opts.ignoreExclusion
    end

    if type(entity) == 'string' then
        suscribedButtons[suscribedButtonsNumber].entitytype = entity
    else
        suscribedButtons[suscribedButtonsNumber].entity = entity
    end

    indexButton(suscribedButtonsNumber, suscribedButtons[suscribedButtonsNumber])
    return suscribedButtonsNumber
end

--- .ContextAddInfo
---@param entity any
---@param name string
---@param condition any
---@param value any
---@param style any
---@param submenu any
---@param opts table|nil -- { serverCondition=string, useScope=bool, order=number, permission=string }
function VFW.ContextAddInfo(entity, name, condition, value, style, submenu, opts)
    if type(entity) == 'string' then
        assert(entity == 'ped' or entity == 'vehicle' or entity == 'object' or entity == 'world',
                'Invalid entity type (ped, vehicle, object, world)')
    end

    suscribedButtonsNumber = suscribedButtonsNumber + 1

    suscribedButtons[suscribedButtonsNumber] = {
        name = name,
        condition = condition,
        value = value,
        style = style or {},
        submenu = submenu
    }

    if opts then
        suscribedButtons[suscribedButtonsNumber].serverCondition = opts.serverCondition
        suscribedButtons[suscribedButtonsNumber].useScope = opts.useScope
        suscribedButtons[suscribedButtonsNumber].order = opts.order
        suscribedButtons[suscribedButtonsNumber].permission = opts.permission
        suscribedButtons[suscribedButtonsNumber].ignoreExclusion = opts.ignoreExclusion
    end

    if type(entity) == 'string' then
        suscribedButtons[suscribedButtonsNumber].entitytype = entity
    else
        suscribedButtons[suscribedButtonsNumber].entity = entity
    end

    indexButton(suscribedButtonsNumber, suscribedButtons[suscribedButtonsNumber])
    return suscribedButtonsNumber
end

--- Delete VFW.ContextButton
---@param buttonId number|string
function VFW.ContextRemoveButton(buttonId)
    unindexButton(buttonId)
    suscribedButtons[buttonId] = nil
end

--- Close the context menu programmatically
function VFW.CloseContextMenu()
    closeContextMenu()
end

-- ============================================
-- POSITION-BASED CONTEXT MENU SYSTEM
-- ============================================

--- Helper to find if a world position matches any registered position
---@param worldPos vector3
---@return number|nil positionId, table|nil positionData
FindMatchingPosition = function(worldPos)
    if not worldPos then
        return nil, nil
    end

    for id = 1, suscribedPositionsNumber do
        local posData = suscribedPositions[id]
        if posData then
            local dist = #(vector3(worldPos.x, worldPos.y, worldPos.z) - posData.position)
            if dist <= posData.radius then
                return id, posData
            end
        end
    end
    return nil, nil
end

--- Check if any position-based entry exists for a world position
---@param worldPos vector3
---@return boolean
HasAnyPositionEntry = function(worldPos)
    local posId, posData = FindMatchingPosition(worldPos)
    if not posId then
        return false
    end

    -- Check if any button in this position passes its condition
    for btnId, btn in pairs(posData.buttons or {}) do
        if not btn.submenu then
            -- Only root level buttons
            if condOk(btn, 0, nil) then
                return true
            end
        end
    end
    return false
end

--- Register a position for context menu
---@param position vector3 The world position
---@param radius number Detection radius (default 1.0)
---@return number positionId
function VFW.ContextRegisterPosition(position, radius)
    suscribedPositionsNumber = suscribedPositionsNumber + 1
    suscribedPositions[suscribedPositionsNumber] = {
        position = position,
        radius = radius or 1.0,
        buttons = {},
        buttonCount = 0
    }
    return suscribedPositionsNumber
end

--- Unregister a position
---@param positionId number
function VFW.ContextUnregisterPosition(positionId)
    suscribedPositions[positionId] = nil
end

--- Add a submenu to a registered position
---@param positionId number The position ID from ContextRegisterPosition
---@param name string Display name
---@param condition function|boolean|nil Condition to show
---@param style table|nil Style options
---@param submenu number|nil Parent submenu ID (nil for root)
---@param opts table|nil -- { permission=string }
---@return number buttonId
function VFW.ContextAddPositionSubmenu(positionId, name, condition, style, submenu, opts)
    local posData = suscribedPositions[positionId]
    if not posData then
        console.debug("[ContextMenu] Position not found:", positionId)
        return -1
    end

    posData.buttonCount = posData.buttonCount + 1
    local btnId = posData.buttonCount

    posData.buttons[btnId] = {
        id = btnId,
        positionId = positionId,
        name = name,
        condition = condition,
        style = style or {},
        submenu = submenu,
        isSubmenu = true,
        isPosition = true,
        permission = opts and opts.permission or nil
    }

    return btnId
end

--- Add a button to a registered position
---@param positionId number The position ID from ContextRegisterPosition
---@param name string Display name
---@param condition function|boolean|nil Condition to show
---@param callback function Callback when clicked
---@param style table|nil Style options
---@param submenu number|nil Parent submenu ID (nil for root)
---@param opts table|nil -- { permission=string }
---@return number buttonId
function VFW.ContextAddPositionButton(positionId, name, condition, callback, style, submenu, opts)
    local posData = suscribedPositions[positionId]
    if not posData then
        console.debug("[ContextMenu] Position not found:", positionId)
        return -1
    end

    posData.buttonCount = posData.buttonCount + 1
    local btnId = posData.buttonCount

    posData.buttons[btnId] = {
        id = btnId,
        positionId = positionId,
        name = name,
        condition = condition,
        callback = callback,
        style = style or {},
        submenu = submenu,
        isPosition = true,
        permission = opts and opts.permission or nil
    }

    return btnId
end

--- Add an info display to a registered position
---@param positionId number The position ID from ContextRegisterPosition
---@param name string Display name
---@param condition function|boolean|nil Condition to show
---@param value any|function Value to display
---@param style table|nil Style options
---@param submenu number|nil Parent submenu ID (nil for root)
---@param opts table|nil -- { permission=string }
---@return number buttonId
function VFW.ContextAddPositionInfo(positionId, name, condition, value, style, submenu, opts)
    local posData = suscribedPositions[positionId]
    if not posData then
        console.debug("[ContextMenu] Position not found:", positionId)
        return -1
    end

    posData.buttonCount = posData.buttonCount + 1
    local btnId = posData.buttonCount

    posData.buttons[btnId] = {
        id = btnId,
        positionId = positionId,
        name = name,
        condition = condition,
        value = value,
        style = style or {},
        submenu = submenu,
        isPosition = true,
        permission = opts and opts.permission or nil
    }

    return btnId
end

--- Remove a button from a position
---@param positionId number
---@param buttonId number
function VFW.ContextRemovePositionButton(positionId, buttonId)
    local posData = suscribedPositions[positionId]
    if posData and posData.buttons then
        posData.buttons[buttonId] = nil
    end
end
