---@meta _
---@diagnostic disable: duplicate-doc-field

local listMenuOpen = false
local addMenuOpen = false
local actualDeco = {}
local editMode = false
local selectedMenu = VFW.CreateOutlineInstance(2, "SELECT", 204)
local hovered = VFW.CreateOutlineInstance(1, "WHITE", 204)
local selected = VFW.CreateOutlineInstance(3, "YELLOW", 255)
local inInterior = false
local actualType = nil
---Load InfoKeys
local function loadInfoKeys()
    SendNUIMessage({
        action = 'nui:infokey:data',
        data = {
            { key = "leftclick", desc = "Sélectionner l'objet" },
            { key = "rightclick", desc = "Bouger la caméra" }
        }
    })
end

--- .Deco
---@param state any
---@param newActualType any
function VFW.Deco(state, newActualType)
    inInterior = state
    actualType = newActualType

    SendNUIMessage({
        action = "nui:deco:visible",
        data = inInterior
    })

    if not inInterior then
        if editMode then
            VFW.ToggleDecoEditMode()
        end

        VFW.RemoveDeco()
    end
end

local timedOut <const> = 5000
---Load VFW.DecoObject
---@param object any
---@param old any
---@return any
function VFW.LoadDecoObject(object, old)
    local hash = joaat(object.model)

    if not IsModelInCdimage(hash) then
        console.debug("Model not found in cdimage: ", object.model)
        return
    end

    local startTime <const> = GetGameTimer()
    RequestModel(hash)
    while not HasModelLoaded(hash) and GetGameTimer() - startTime < timedOut do
        Wait(50)
    end
    
    object.old = old
    object.obj = CreateObject(hash, object.pos.x, object.pos.y, object.pos.z, false, false, false)
    SetEntityCoords(object.obj, object.pos.x, object.pos.y, object.pos.z)
    SetEntityRotation(object.obj, object.rot.x, object.rot.y, object.rot.z)
    FreezeEntityPosition(object.obj, true)
    SetModelAsNoLongerNeeded(hash)

    local id = #actualDeco + 1
    actualDeco[id] = object
    return id
end

---Save VFW.Deco
function VFW.SaveDeco()
    local result = {}

    for i = 1, #actualDeco do
        if (actualDeco[i].obj ~= nil) and DoesEntityExist(actualDeco[i].obj ) then
            result[#result + 1] = {
                model = actualDeco[i].model,
                pos = GetEntityCoords(actualDeco[i].obj),
                rot = GetEntityRotation(actualDeco[i].obj)
            }
        end
    end

    return result
end

---Set VFW.ReDeco
function VFW.ResetDeco()
    for i = 1, #actualDeco do
        :: restart ::
        if not actualDeco[i] then
            break
        end

        if actualDeco[i].obj then
            DeleteObject(actualDeco[i].obj)
        end

        if actualDeco[i].old then
            actualDeco[i].obj = CreateObject(actualDeco[i].model, actualDeco[i].pos.x, actualDeco[i].pos.y, actualDeco[i].pos.z, false, false, false)
            SetEntityCoords(actualDeco[i].obj, actualDeco[i].pos.x, actualDeco[i].pos.y, actualDeco[i].pos.z)
            SetEntityRotation(actualDeco[i].obj, actualDeco[i].rot.x, actualDeco[i].rot.y, actualDeco[i].rot.z)
            FreezeEntityPosition(actualDeco[i].obj, true)
            SetModelAsNoLongerNeeded(actualDeco[i].model)
        else
            table.remove(actualDeco, i)
            goto restart
        end
    end
end

local decoGeneration = 0

---Load VFW.Deco
---@param deco any
function VFW.LoadDeco(deco)
---@class actualDeco
    actualDeco = {}
    decoGeneration = decoGeneration + 1
    local generation = decoGeneration
    CreateThread(function()
        for i = 1, #deco do
            if generation ~= decoGeneration then
                return
            end

            local id = VFW.LoadDecoObject(deco[i], true)

            if generation ~= decoGeneration then
                if id and actualDeco[id] then
                    if actualDeco[id].obj then
                        DeleteObject(actualDeco[id].obj)
                    end
                    actualDeco[id] = nil
                end
                return
            end
        end
    end)
end

--- .FormatDeco
function VFW.FormatDeco()
    local result = {}

    for i = 1, #actualDeco do
        if (actualDeco[i].obj ~= nil) and DoesEntityExist(actualDeco[i].obj ) then
            result[#result + 1] = {
                label = actualDeco[i].model,
                model = i
            }
        end
    end

    return result
end

--- .IsObjectADeco
---@param object any
---@return any
function VFW.IsObjectADeco(object)
    for i = 1, #actualDeco do
        if actualDeco[i].obj == object then
            return actualDeco[i]
        end
    end

    return false
end

---Delete VFW.Deco
function VFW.RemoveDeco()
    decoGeneration = decoGeneration + 1

    for i = 1, #actualDeco do
        DeleteObject(actualDeco[i].obj)
    end

---@class actualDeco
    actualDeco = {}
end

RegisterNUICallback("nui:deco:save", function(data)
    if data.type == "apply" then
        TriggerServerEvent("vfw:property:applySave", VFW.ActualProperty, data.id)
    else
        local result = TriggerServerCallback("vfw:property:deleteSave", data.id) or {}

        SendNUIMessage({
            action = "nui:deco:updateSave",
            data = {
                premium = VFW.PlayerGlobalData.permissions["vip_gold"] and 3 or VFW.PlayerGlobalData.permissions["vip_silver"] and 2 or VFW.PlayerGlobalData.permissions["vip_bronze"] and 1 or 0,
                actualType = actualType,
                list = result,
            }
        })
    end
end)

RegisterNUICallback("nui:deco:newCopy", function(data)
    local result = TriggerServerCallback("vfw:property:createSave", data.name, VFW.ActualProperty) or {}

    SendNUIMessage({
        action = "nui:deco:updateSave",
        data = {
            premium = VFW.PlayerGlobalData.permissions["vip_gold"] and 3 or VFW.PlayerGlobalData.permissions["vip_silver"] and 2 or VFW.PlayerGlobalData.permissions["vip_bronze"] and 1 or 0,
            actualType = actualType,
            list = result,
        }
    })
end)

RegisterNUICallback("nui:deco:getSave", function(_, cb)
    cb({
        premium = VFW.PlayerGlobalData.permissions["vip_gold"] and 3 or VFW.PlayerGlobalData.permissions["vip_silver"] and 2 or VFW.PlayerGlobalData.permissions["vip_bronze"] and 1 or 0,
        actualType = actualType,
        list = TriggerServerCallback("vfw:property:getSave") or {},
    })
end)

--- MenuList
---@return any
local function MenuList()
    local data = {
        style = {
            menuStyle = "custom",
            bannerType = 2,
            gridType = 7,
            buyType = 2,
            buyTextType = false,
            buyText = "Selectionner",
            backgroundType = 1,
            bannerImg = "assets/catalogues/headers/header_dynasty.webp",
            itemsTop = "Liste des objets",
            propsSchearch = 2,
        },
        cdnURL = "items",
        eventName = "decoList",
        showStats = { show = false },
        category = { show = false },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        mouseEvents = false,
        color = { show = false },
        items = VFW.FormatDeco()
    }
    return data
end

--- MenuAdd
---@return any
local function MenuAdd()
    local data = {
        style = {
            menuStyle = "custom",
            bannerType = 2,
            gridType = 7,
            buyType = 3,
            backgroundType = 1,
            bannerImg = "assets/catalogues/headers/header_dynasty.webp",
            itemsTop = "Historique des objets",
            propsSchearch = 1,
        },
        cdnURL = "items",
        eventName = "decoAdd",
        showStats = { show = false },
        category = { show = false },
        cameras = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        mouseEvents = false,
        color = { show = false },
        items = VFW.FormatDeco()
    }
    return data
end

RegisterNUICallback("nui:deco:button", function(data)
    if data.type == "add" then
        addMenuOpen = not addMenuOpen
        SendNUIMessage({
            action = "nui:bigmenu:visible",
            data = addMenuOpen,
        })
        if addMenuOpen then
            SendNUIMessage({
                action = "nui:bigmenu:setData",
                data = MenuAdd()
            })
        end

        SendNUIMessage({
            action = "nui:deco:changeSelect",
            data = {
                category = "add",
                value = addMenuOpen,
            }
        })
    elseif data.type == "list" then
        listMenuOpen = not listMenuOpen
        SendNUIMessage({
            action = "nui:bigmenu:visible",
            data = listMenuOpen,
        })
        if listMenuOpen then
            SendNUIMessage({
                action = "nui:bigmenu:setData",
                data = MenuList()
            })
        end

        SendNUIMessage({
            action = "nui:deco:changeSelect",
            data = {
                category = "list",
                value = listMenuOpen,
            }
        })
    elseif data.type == "edit" then
        VFW.ToggleDecoEditMode()
    end
end)

--- .ToggleDecoEditMode
function VFW.ToggleDecoEditMode()
    editMode = not editMode
    FreezeEntityPosition(VFW.PlayerData.ped, editMode)
    SetEntityAlpha(VFW.PlayerData.ped, editMode and 51 or 255, false)

    if not editMode then
        if addMenuOpen then
            SendNUIMessage({
                action = "nui:deco:changeSelect",
                data = {
                    category = "add",
                    value = false,
                }
            })
            SendNUIMessage({
                action = "nui:bigmenu:visible",
                data = false,
            })
            addMenuOpen = false
        end

        if listMenuOpen then
            SendNUIMessage({
                action = "nui:deco:changeSelect",
                data = {
                    category = "list",
                    value = false,
                }
            })
            SendNUIMessage({
                action = "nui:bigmenu:visible",
                data = false,
            })
            listMenuOpen = false
        end
    end
    
    SendNUIMessage({
        action = "nui:deco:changeSelect",
        data = {
            category = "edit",
            value = editMode,
        }
    })
    
    SendNUIMessage({
        action = 'nui:infokey:visible',
        data = editMode
    })
    loadInfoKeys()

    VFW.Nui.HudVisible(not editMode)
    VFW.DisableEscapeMenu(editMode)
    Worlds.Zone.HideInteract(not editMode)

    if not editMode then
        if VFW.Nui.ValideInput(true, "Confirmer la modification") then
            TriggerServerEvent("vfw:property:saveDeco", VFW.ActualProperty, VFW.SaveDeco())
        else
            VFW.ResetDeco()
        end
    end

    local lastCursor = nil
    VFW.TogglePlayerFreecam(editMode, {
        rightClickRotation = true,
        distance = 15.0,
        getCenter = function()
            return GetEntityCoords(VFW.PlayerData.ped)
        end,
        getCursorPos = function()
            return lastCursor
        end
    })

    CreateThread(function()
        local frameCounter = 0
        EnterCursorMode()
        while editMode do
            DisableAllControlActions(0)
            if IsDisabledControlJustPressed(0, 25) then
                lastCursor = VFW.GetCursorScreenPosition()
            elseif IsDisabledControlJustReleased(0, 25) then
                lastCursor = nil
            elseif IsDisabledControlPressed(0, 25) then
                SetCursorLocation(lastCursor.x, lastCursor.y)
            end

            if IsDisabledControlJustPressed(0, 201) then
                if selected.entity then
                    local data = VFW.StopGizmo()
                    if data.handle == selected.entity then
                        SetEntityCoords(data.handle, data.pos.x, data.pos.y, data.pos.z)
                        SetEntityRotation(data.handle, data.rot.x, data.rot.y, data.rot.z)
                    end

                    selected.deselectEntity()
                    loadInfoKeys()
                end
            elseif IsDisabledControlJustPressed(0, 194) then
                if selected.entity then
                    local entity = selected.entity
                    VFW.StopGizmo()
                    selected.deselectEntity()
                    DeleteEntity(entity)
                    loadInfoKeys()
                end
            elseif IsDisabledControlJustPressed(0, 200) then
                if selected.entity then
                    local obj = VFW.IsObjectADeco(selected.entity)
                    SetEntityCoords(selected.entity, obj.pos.x, obj.pos.y, obj.pos.z)
                    SetEntityRotation(selected.entity, obj.rot.x, obj.rot.y, obj.rot.z)
                    VFW.StopGizmo()
                    selected.deselectEntity()
                    loadInfoKeys()
                end
            end

            if not selected.entity then
                if frameCounter > 25 then
                    frameCounter = 0
                    if not IsDisabledControlPressed(0, 25) then
                        local CURSOR_POSITION <const> = VFW.GetCursorScreenPosition()
                        local HIT <const>, WORLD_POSITION <const>, NORMAL_DIRECTION <const>, ENTITY <const> = VFW.RaycastScreenFreecam(CURSOR_POSITION, 50.0, nil)
        
                        if HIT and ENTITY and (GetEntityType(ENTITY) == 3) and VFW.IsObjectADeco(ENTITY) then
                            hovered.selectEntity(ENTITY)
                        else
                            hovered.deselectEntity()
                        end
                    end
                end

                if IsDisabledControlJustPressed(0, 24) and hovered.entity then
                    VFW.UseGizmo(hovered.entity)
                    selected.selectEntity(hovered.entity)
                end
            end

            frameCounter = frameCounter + 1
            Wait(0)
        end

        selectedMenu.deselectEntity()
        hovered.deselectEntity()
        if selected.entity then
            local obj = VFW.IsObjectADeco(selected.entity)
            SetEntityCoords(selected.entity, obj.pos.x, obj.pos.y, obj.pos.z)
            SetEntityRotation(selected.entity, obj.rot.x, obj.rot.y, obj.rot.z)
            VFW.StopGizmo()
            selected.deselectEntity()
        end

        LeaveCursorMode()
    end)
end

RegisterNuiCallback("nui:newgrandcatalogue:decoList:selectGridType7", function(data)
    if not data or not actualDeco[data] then
        return
    end

    selectedMenu.selectEntity(actualDeco[data].obj)
end)

local hoveredMenu = nil
RegisterNuiCallback("nui:newgrandcatalogue:decoList:hoverGridType7", function(data)
    hoveredMenu = nil
    
    if not data or not actualDeco[data] then
        return
    end

    hoveredMenu = actualDeco[data].obj
    while hoveredMenu == actualDeco[data].obj do
        VFW.DrawEntityBoundingBox(hoveredMenu)
        Wait(0)
    end
end)

RegisterNUICallback("nui:newgrandcatalogue:decoList:close", function()
    selectedMenu.deselectEntity()
    hoveredMenu = nil

    listMenuOpen = false
    SendNUIMessage({
        action = "nui:bigmenu:visible",
        data = false,
    })
    
    SendNUIMessage({
        action = "nui:deco:changeSelect",
        data = {
            category = "list",
            value = false,
        }
    })
end)

RegisterNUICallback("nui:newgrandcatalogue:decoList:focus", function()
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback("nui:newgrandcatalogue:decoList:unfocus", function()
    SetNuiFocusKeepInput(true)
end)

RegisterNUICallback("nui:newgrandcatalogue:decoList:selectBuy", function(data)
    selectedMenu.deselectEntity()
    hoveredMenu = nil

    listMenuOpen = false
    SendNUIMessage({
        action = "nui:bigmenu:visible",
        data = false,
    })

    SendNUIMessage({
        action = "nui:deco:changeSelect",
        data = {
            category = "list",
            value = false,
        }
    })

    if not data or not actualDeco[data] then
        return
    end

    if selected.entity then
        local obj = VFW.IsObjectADeco(selected.entity)
        SetEntityCoords(selected.entity, obj.pos.x, obj.pos.y, obj.pos.z)
        SetEntityRotation(selected.entity, obj.rot.x, obj.rot.y, obj.rot.z)
        VFW.StopGizmo()
        selected.deselectEntity()
        loadInfoKeys()
    end

    VFW.UseGizmo(actualDeco[data].obj)
    selected.selectEntity(actualDeco[data].obj)
end)

RegisterNUICallback("nui:newgrandcatalogue:decoAdd:close", function()
    addMenuOpen = false
    SendNUIMessage({
        action = "nui:bigmenu:visible",
        data = false,
    })

    SendNUIMessage({
        action = "nui:deco:changeSelect",
        data = {
            category = "add",
            value = false,
        }
    })
end)

RegisterNUICallback("nui:newgrandcatalogue:decoAdd:search", function(data, cb)
    cb(IsModelValid(joaat(data)))
end)

RegisterNUICallback("nui:newgrandcatalogue:decoAdd:focus", function()
    SetNuiFocusKeepInput(false)
end)

RegisterNUICallback("nui:newgrandcatalogue:decoAdd:unfocus", function()
    SetNuiFocusKeepInput(true)
end)

RegisterNUICallback("nui:newgrandcatalogue:decoAdd:selectBuy", function(data)
    local pos = GetEntityCoords(VFW.PlayerData.ped)
    local HIT <const>, WORLD_POSITION <const>, _, _ = VFW.RaycastScreenFreecam(vec2(0.5, 0.5), 50.0, nil)
    if HIT then
        pos = WORLD_POSITION
    end

    addMenuOpen = false
    SendNUIMessage({
        action = "nui:bigmenu:visible",
        data = false,
    })

    SendNUIMessage({
        action = "nui:deco:changeSelect",
        data = {
            category = "add",
            value = false,
        }
    })

    local id = VFW.LoadDecoObject({
        model = data,
        pos = GetEntityCoords(VFW.PlayerData.ped)+vector3(1, 0, 0),
        rot = vector3(0, 0, 0)
    })

    if selected.entity then
        local obj = VFW.IsObjectADeco(selected.entity)
        SetEntityCoords(selected.entity, obj.pos.x, obj.pos.y, obj.pos.z)
        SetEntityRotation(selected.entity, obj.rot.x, obj.rot.y, obj.rot.z)
        VFW.StopGizmo()
        selected.deselectEntity()
        loadInfoKeys()
    end

    VFW.UseGizmo(actualDeco[id].obj)
    selected.selectEntity(actualDeco[id].obj)
end)

---@param deco any
RegisterNetEvent("vfw:property:updateDeco", function(deco)
    VFW.RemoveDeco()
    VFW.LoadDeco(deco)
end)