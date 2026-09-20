---@meta _
---@diagnostic disable: duplicate-doc-field

--[[
    ========================================
    OBJECT CONTEXT MENU - Actions Dev
    ========================================
]]

--region ====== HELPER FUNCTIONS ======

local function HasDevPermission(permission)
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions[permission] or false
end

local function canShowDevMenu(object)
    return DoesEntityExist(object) and HasDevPermission("dev") and VFW.IsInStaffMode()
end

local function canDeleteObject(object)
    return DoesEntityExist(object) and HasDevPermission("alt_delete_entity") and VFW.IsInStaffMode()
end

local function formatNumber(num)
    return tonumber(string.format("%.2f", num))
end

local function formatNumberPrecise(num)
    return tonumber(string.format("%.6f", num))
end

--endregion

--region ====== SUBMENUS ======

local devSubmenu = VFW.ContextAddSubmenu("object", ":monitor: Action Dev", canShowDevMenu, { color = { 255, 64, 64 } }, nil)

local infoSubmenu = VFW.ContextAddSubmenu("object", ":chart: Informations", canShowDevMenu, {}, devSubmenu)

local positionSubmenu = VFW.ContextAddSubmenu("object", ":pin: Position & Déplacement", canShowDevMenu, {}, devSubmenu)

--endregion

--region ====== INFORMATIONS ======

VFW.ContextAddInfo("object", ":hash: ID Entité", canShowDevMenu, function(object)
    return tostring(object)
end, {}, infoSubmenu)

VFW.ContextAddInfo("object", ":tag: Modèle", canShowDevMenu, function(object)
    return GetEntityArchetypeName(object) or "Inconnu"
end, {}, infoSubmenu)

VFW.ContextAddInfo("object", ":key: Hash", canShowDevMenu, function(object)
    return tostring(GetEntityModel(object))
end, {}, infoSubmenu)

VFW.ContextAddInfo("object", ":user: Owner", canShowDevMenu, function(object)
    local owner = NetworkGetEntityOwner(object)
    return owner and ("#" .. GetPlayerServerId(owner)) or "Serveur"
end, {}, infoSubmenu)

VFW.ContextAddInfo("object", ":ruler: Type", canShowDevMenu, function(object)
    local types = { [1] = "Ped", [2] = "Vehicle", [3] = "Object" }
    return types[GetEntityType(object)] or "Inconnu"
end, {}, infoSubmenu)

VFW.ContextAddButton("object", ":report: Copier le nom", canShowDevMenu, function(object)
    local name = GetEntityArchetypeName(object) or "unknown"
  VFW.Clipboard(name)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Nom copié: " .. name .. "." })
end, {}, infoSubmenu)

VFW.ContextAddButton("object", ":report: Copier le hash", canShowDevMenu, function(object)
    local hash = GetEntityModel(object)
    VFW.Clipboard(tostring(hash))
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Hash copié: " .. hash .. "." })
end, {}, infoSubmenu)

--endregion

--region ====== POSITION & DEPLACEMENT ======

VFW.ContextAddInfo("object", ":pin: Position", canShowDevMenu, function(object)
    local pos = GetEntityCoords(object)
    return formatNumber(pos.x) .. ", " .. formatNumber(pos.y) .. ", " .. formatNumber(pos.z)
end, {}, positionSubmenu)

VFW.ContextAddInfo("object", ":refresh: Rotation", canShowDevMenu, function(object)
    local rot = GetEntityRotation(object)
    return formatNumber(rot.x) .. ", " .. formatNumber(rot.y) .. ", " .. formatNumber(rot.z)
end, {}, positionSubmenu)

VFW.ContextAddInfo("object", ":compass: Heading", canShowDevMenu, function(object)
    return formatNumber(GetEntityHeading(object)) .. "°"
end, {}, positionSubmenu)

VFW.ContextAddButton("object", ":report: Copier la position", canShowDevMenu, function(object)
    local pos = GetEntityCoords(object)
    local heading = GetEntityHeading(object)
    local posFinal = formatNumberPrecise(pos.x) .. ", " .. formatNumberPrecise(pos.y) .. ", " .. formatNumberPrecise(pos.z) .. ", " .. formatNumber(heading)
    VFW.Clipboard(posFinal)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Position copiée." })
end, {}, positionSubmenu)

VFW.ContextAddButton("object", ":report: Copier vec3", canShowDevMenu, function(object)
    local pos = GetEntityCoords(object)
    local vec3Str = "vector3(" .. formatNumberPrecise(pos.x) .. ", " .. formatNumberPrecise(pos.y) .. ", " .. formatNumberPrecise(pos.z) .. ")"
  VFW.Clipboard(vec3Str)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "vec3 copié." })
end, {}, positionSubmenu)

VFW.ContextAddButton("object", ":report: Copier vec4", canShowDevMenu, function(object)
    local pos = GetEntityCoords(object)
    local heading = GetEntityHeading(object)
    local vec4Str = "vector4(" .. formatNumberPrecise(pos.x) .. ", " .. formatNumberPrecise(pos.y) .. ", " .. formatNumberPrecise(pos.z) .. ", " .. formatNumber(heading) .. ")"
  VFW.Clipboard(vec4Str)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "vec4 copié." })
end, {}, positionSubmenu)

VFW.ContextAddButton("object", ":refresh: Déplacer", canShowDevMenu, function(object)
    Target:MouveEntity(object)
end, {}, positionSubmenu)

VFW.ContextAddButton("object", ":report: Dupliquer", canShowDevMenu, function(object)
    local new = Target:DuplicateEntity(object)
    Target:MouveEntity(new)
    VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Objet dupliqué." })
end, {}, positionSubmenu)

--endregion

--region ====== ACTIONS ======

VFW.ContextAddButton("object", ":sparkles: Freeze/Unfreeze", canShowDevMenu, function(object)
    local isFrozen = IsEntityPositionFrozen(object)
    NetworkRequestControlOfEntity(object)
    FreezeEntityPosition(object, not isFrozen)
    VFW.ShowNotification({
        type = 'STAFF', variant = isFrozen and 'SUCCESS' or 'INFO', subtitle = 'Gestion Objets',
        message = isFrozen and "Objet libéré." or "Objet gelé."
  })
end, {}, devSubmenu)

VFW.ContextAddButton("object", ":trash: Supprimer", canDeleteObject, function(object)
    if not DoesEntityExist(object) then return end

    -- Props Builder (VIP/Staff) : supprimer via le système props builder pour sync DB + tous les joueurs
    if PropsBuilder and PropsBuilder.cache and PropsBuilder.cache.props then
        for propId, propInstance in pairs(PropsBuilder.cache.props) do
            if propInstance.object == object then
                TriggerServerEvent("propsBuilder:deleteProp", propId)
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Prop builder supprimé (DB + sync)." })
                return
            end
        end
    end

    local isStaff, staffPropId = IsStaffProp(object)
    if isStaff and staffPropId then
        TriggerServerEvent("vfw:staff:deleteProp", staffPropId)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Staff prop supprimé." })
        return
    end

    local jobProp = Entity(object).state.jobProp
    if jobProp and NetworkGetEntityIsNetworked(object) then
        local netId = NetworkGetNetworkIdFromEntity(object)
        TriggerServerEvent('jobsPropsMenu:staff:forceRemove', netId)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Prop métier supprimé." })
        return
    end

    local eventNetId = Entity(object).state.eventPropNetId
    if eventNetId then
        TriggerServerEvent("vfw:staff:deleteObject", eventNetId)
        if NetworkGetEntityIsNetworked(object) then
            NetworkRequestControlOfEntity(object)
            local timeout = 0
            while not NetworkHasControlOfEntity(object) and timeout < 20 do
                Wait(100)
                NetworkRequestControlOfEntity(object)
                timeout = timeout + 1
            end
        end
        SetEntityAsMissionEntity(object, false, true)
        DeleteEntity(object)
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Prop animateur supprimé." })
        return
    end

    if IsEntityAttachedToEntity(object) then
        local parent = GetEntityAttachedTo(object)
        if parent and DoesEntityExist(parent) and IsEntityAPed(parent) then
            local playerIndex = NetworkGetPlayerIndexFromPed(parent)
            if playerIndex and playerIndex ~= -1 then
                local targetSrc = GetPlayerServerId(playerIndex)
                if targetSrc and targetSrc > 0 then
                    local modelHash = GetEntityModel(object)
                    local deleted = TriggerServerCallback("vfw:staff:deleteEmoteProp", targetSrc, modelHash)
                    if deleted then
                        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Prop d'animation supprimé." })
                        return
                    end
                end
            end
        end
    end

    local isNetworked = NetworkGetEntityIsNetworked(object)
    local netId = isNetworked and NetworkGetNetworkIdFromEntity(object) or nil

    if isNetworked then
        NetworkRequestControlOfEntity(object)
        local timeout = 0
        while not NetworkHasControlOfEntity(object) and timeout < 20 do
            Wait(100)
            NetworkRequestControlOfEntity(object)
            timeout = timeout + 1
        end
    end

    SetEntityAsMissionEntity(object, false, true)
    DeleteEntity(object)

    if not DoesEntityExist(object) then
        if netId then
            TriggerServerEvent("vfw:staff:deleteObject", netId)
        end
        VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Gestion Objets', message = "Objet supprimé." })
    else
        VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Objets', message = "Impossible de supprimer cet objet." })
    end
end, { color = { 255, 64, 64 } }, devSubmenu)

--endregion

--region ====== STAFF / ANIMATEUR PROPS ======

local function HasPermission(permission)
    return VFW.PlayerGlobalData and VFW.PlayerGlobalData.permissions and VFW.PlayerGlobalData.permissions[permission] or false
end

local function isManageablePropObject(object)
    if not DoesEntityExist(object) then return false end
    if IsStaffProp(object) then return true end
    return Entity(object).state.eventPropNetId ~= nil
end

local function isAnimatorPropObject(object)
    if not isManageablePropObject(object) then return false end
    if not VFW.IsInAnimatorMode() then return false end
    return HasPermission("menu_anim")
end

local function isStaffPropObject(object)
    if not isManageablePropObject(object) then return false end
    if not VFW.IsInStaffMode() then return false end
    return HasPermission("alt_spawn_object")
end

local function MoveProp(object)
    if NetworkGetEntityIsNetworked(object) then
        NetworkRequestControlOfEntity(object)
        local timeout = 0
        while not NetworkHasControlOfEntity(object) and timeout < 20 do
            Wait(50)
            NetworkRequestControlOfEntity(object)
            timeout = timeout + 1
        end
        if not NetworkHasControlOfEntity(object) then
            VFW.ShowNotification({ type = 'STAFF', variant = 'ERROR', subtitle = 'Gestion Objets', message = "Impossible de prendre le contrôle de l'objet." })
            return
        end
        SetEntityAsMissionEntity(object, true, true)
    end

    FreezeEntityPosition(object, false)
    SetEntityAlpha(object, 180, false)
    SetEntityCollision(object, false, false)

    local currentHeading = GetEntityHeading(object)
    local placing = true
    local useGizmo = false

    local instrId = VFW.AddInstructionalButtons({
        { label = "Poser", control = 38 },
        { label = "Tourner", control = 241 },
        { label = "Mode avancé", control = 47 },
        { label = "Annuler", control = 200 },
    })

    while placing do
        Wait(0)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        local fwd = GetEntityForwardVector(ped)
        local targetPos = pCoords + fwd * 2.5

        SetEntityCoords(object, targetPos.x, targetPos.y, targetPos.z, false, false, false, false)
        PlaceObjectOnGroundProperly(object)
        SetEntityHeading(object, currentHeading)

        DisableControlAction(0, 15, true)
        DisableControlAction(0, 16, true)
        if IsDisabledControlJustPressed(0, 15) then
            currentHeading = currentHeading + 15.0
        end
        if IsDisabledControlJustPressed(0, 16) then
            currentHeading = currentHeading - 15.0
        end

        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 140, true)
        DisablePlayerFiring(ped, true)

        if VFW.Interact.JustPressed(0, 38) then
            placing = false
        end

        if IsControlJustPressed(0, 47) then
            placing = false
            useGizmo = true
        end

        if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then
            placing = false
        end
    end

    VFW.RemoveInstructionalButtons(instrId)

    if useGizmo then
        exports["core"]:useGizmo(object)
    end

    ResetEntityAlpha(object)
    SetEntityCollision(object, true, true)
    FreezeEntityPosition(object, true)
end

local function DeleteProp(object)
    local isStaff, staffPropId = IsStaffProp(object)
    if isStaff and staffPropId then
        TriggerServerEvent("vfw:staff:deleteProp", staffPropId)
        return
    end

    local eventNetId = Entity(object).state.eventPropNetId
    if eventNetId then
        TriggerServerEvent("vfw:staff:deleteObject", eventNetId)
        if NetworkGetEntityIsNetworked(object) then
            NetworkRequestControlOfEntity(object)
            local timeout = 0
            while not NetworkHasControlOfEntity(object) and timeout < 20 do
                Wait(100)
                NetworkRequestControlOfEntity(object)
                timeout = timeout + 1
            end
        end
        SetEntityAsMissionEntity(object, false, true)
        DeleteEntity(object)
    end
end

-- Animator submenu (perm: menu_anim + animator mode)
local animatorPropSubmenu = VFW.ContextAddSubmenu("object", ":mask: Action Animateur", isAnimatorPropObject, { color = { 100, 180, 255 } }, nil)
VFW.ContextAddButton("object", ":refresh: Déplacer", isAnimatorPropObject, MoveProp, {}, animatorPropSubmenu)
VFW.ContextAddButton("object", ":trash: Supprimer", isAnimatorPropObject, DeleteProp, { color = { 255, 64, 64 } }, animatorPropSubmenu)

-- Staff submenu (perm: contextmenu + staff mode)
local staffPropSubmenu = VFW.ContextAddSubmenu("object", ":police: Actions Staff", isStaffPropObject, { color = { 255, 64, 64 } }, nil)
VFW.ContextAddButton("object", ":refresh: Déplacer", isStaffPropObject, MoveProp, {}, staffPropSubmenu)
VFW.ContextAddButton("object", ":trash: Supprimer", isStaffPropObject, DeleteProp, { color = { 255, 64, 64 } }, staffPropSubmenu)

--endregion
