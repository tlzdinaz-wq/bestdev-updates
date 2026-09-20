---@meta _
---@diagnostic disable: duplicate-doc-field

---Get PropertyByName
---@param name string
---@return string
local function GetPropertyByName(name)

    for k, v in pairs(Property) do
        for i = 1, #v.data do
            if v.data[i].name == name then
                return v.data[i]
            end
        end
    end

    return false
end

local markerThreadActive = false
VFW.PropertyChoiceResult = nil

--- Clear all non-player peds in the property interior
---@param coords vector3
---@param radius number
local function ClearInteriorPeds(coords, radius)
    local handle, ped = FindFirstPed()
    local success = true
    while success do
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) then
            local pedCoords = GetEntityCoords(ped)
            if #(pedCoords - coords) <= radius then
                DeleteEntity(ped)
            end
        end
        success, ped = FindNextPed(handle)
    end
    EndFindPed(handle)
end

---Handle deleting
local function deletingHandle()
    markerThreadActive = false
    VFW.Deco(false)
end

--- Draw a marker on the ground
---@param coords vector3
---@param r number
---@param g number
---@param b number
local function DrawGroundMarker(coords, r, g, b)
    DrawMarker(25, coords.x, coords.y, coords.z - 1.0, 0, 0, 0, 0, 0, 0, 0.8, 0.8, 0.5, r, g, b, 120, false, true, 2, false, nil, nil, false)
end

--- .EnterHouse
---@param propertyInfo any
---@param force any
---@return any
function VFW.EnterHouse(propertyInfo, force)
    local property = GetPropertyByName(propertyInfo.name)
    if not property then
        return
    end

    deletingHandle()

    if not force then
        DoScreenFadeOut(500)
        Wait(500)
        FreezeEntityPosition(VFW.PlayerData.ped, true)
        if property.ipl then
            property.ipl()
        end

        SetEntityCoords(VFW.PlayerData.ped, property.leave-vec3(0,0,0.9))

        if propertyInfo.deco then
            VFW.LoadDeco(propertyInfo.deco)
        end

        Wait(500)
        ClearInteriorPeds(property.leave, 100.0)
        FreezeEntityPosition(VFW.PlayerData.ped, false)
        DoScreenFadeIn(500)
    else
        if property.ipl then
            property.ipl()
        end

        if propertyInfo.deco then
            VFW.LoadDeco(propertyInfo.deco)
        end

        ClearInteriorPeds(property.leave, 100.0)
    end

    VFW.Deco(true, propertyInfo.name)

    local leavePos = property.leave
    local coffrePos = property.coffre
    local vestiairePos = property.vestiaire or (coffrePos and (coffrePos + vector3(-1.5, 0.0, 0.0))) or nil
    local interactDist = 1.5
    VFW.PropertyCanManage = TriggerServerCallback("vfw:property:canManage", VFW.ActualProperty)

    markerThreadActive = true
    local lastPermCheck = GetGameTimer()
    CreateThread(function()
        while markerThreadActive do
            local sleep = 500
            local now = GetGameTimer()
            if now - lastPermCheck > 10000 then
                lastPermCheck = now
                VFW.PropertyCanManage = TriggerServerCallback("vfw:property:canManage", VFW.ActualProperty)
            end
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distLeave = #(playerCoords - leavePos)
            local distCoffre = #(playerCoords - coffrePos)
            local distVestiaire = vestiairePos and #(playerCoords - vestiairePos) or 9999.0

            if distLeave > 100.0 then
                deletingHandle()
                TriggerServerEvent("vfw:leaveProperty", VFW.ActualProperty)
                return
            end

            if distLeave < 10.0 or distCoffre < 10.0 or distVestiaire < 10.0 then
                sleep = 0

                DrawGroundMarker(leavePos, 45, 124, 40)
                DrawGroundMarker(coffrePos, 66, 135, 245)
                if vestiairePos then
                    DrawGroundMarker(vestiairePos, 230, 180, 60)
                end

                -- Leave / Gestion marker
                if distLeave < interactDist and not gestionOpen then
                    VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Sortir" .. (VFW.PropertyCanManage and " / Gérer" or ""), nil, false)

                    if VFW.Interact.JustPressed(0, 51) then -- E
                        if VFW.PropertyCanManage then
                            -- Open choice UI
                            VFW.PropertyChoiceResult = nil
                            SendNUIMessage({ action = "nui:property-choice:visible", data = true })
                            VFW.Nui.Focus(true, false)

                            local choiceDeadline = GetGameTimer() + 15000
                            while VFW.PropertyChoiceResult == nil do
                                if GetGameTimer() > choiceDeadline then
                                    VFW.PropertyChoiceResult = "cancel"
                                    break
                                end
                                Wait(100)
                            end

                            SendNUIMessage({ action = "nui:property-choice:visible", data = false })
                            if VFW.PropertyChoiceResult ~= "manage" then
                                VFW.Nui.Focus(false)
                            end

                            if VFW.PropertyChoiceResult == "manage" then
                                VFW.OpenPropertyGestion()
                            elseif VFW.PropertyChoiceResult == "leave" then
                                deletingHandle()
                                DoScreenFadeOut(500)
                                Wait(1000)
                                FreezeEntityPosition(VFW.PlayerData.ped, true)
                                TriggerServerEvent("vfw:leaveProperty", VFW.ActualProperty)
                                Wait(1000)
                                FreezeEntityPosition(VFW.PlayerData.ped, false)
                                DoScreenFadeIn(500)
                                return
                            end
                        else
                            deletingHandle()
                            DoScreenFadeOut(500)
                            Wait(1000)
                            FreezeEntityPosition(VFW.PlayerData.ped, true)
                            TriggerServerEvent("vfw:leaveProperty", VFW.ActualProperty)
                            Wait(1000)
                            FreezeEntityPosition(VFW.PlayerData.ped, false)
                            DoScreenFadeIn(500)
                            return
                        end
                    end
                end

                -- Chest marker
                if distCoffre < interactDist then
                    VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Ouvrir le coffre", nil, false)

                    if VFW.Interact.JustPressed(0, 51) then -- E
                        VFW.OpenChest(("property:%s"):format(VFW.ActualProperty), "property")
                    end
                end

                -- Vestiaire marker
                if vestiairePos and distVestiaire < interactDist then
                    VFW.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ Ouvrir le vestiaire", nil, false)

                    if VFW.Interact.JustPressed(0, 51) then -- E
                        if VFW.OpenPropertyVestiaire then
                            VFW.OpenPropertyVestiaire(VFW.ActualProperty)
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

-- =============================================
-- Property Gestion NUI (new system)
-- =============================================

gestionOpen = false

--- Open the property gestion NUI
function VFW.OpenPropertyGestion()
    gestionOpen = true
    VFW.Nui.Focus(true)
    VFW.Nui.HudVisible(false)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({
        action = "nui:property-gestion:visible",
        data = true
    })

    local gestionData = TriggerServerCallback("vfw:property:getGestion", VFW.ActualProperty)
    if not gestionData then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Impossible d'accéder à la gestion."
        })
        VFW.ClosePropertyGestion()
        return
    end

    SendNUIMessage({
        action = "nui:property-gestion:data",
        data = gestionData
    })
end

--- Close the property gestion NUI
function VFW.ClosePropertyGestion()
    gestionOpen = false
    VFW.Nui.Focus(false)
    VFW.Nui.HudVisible(true)
    SendNUIMessage({
        action = "nui:property-gestion:visible",
        data = false
    })
end

--- NUI Callback: close
RegisterNUICallback("nui:property-gestion:close", function(_, cb)
    VFW.ClosePropertyGestion()
    cb({})
end)

--- NUI Callback: pay rent
RegisterNUICallback("nui:property-gestion:payRent", function(data, cb)
    local success, result = TriggerServerCallback("vfw:property:payRent", VFW.ActualProperty, data.weeks, data.paymentMethod)
    if success then
        cb({ success = true, days = result })
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = result or "Erreur lors du paiement."
        })
        cb({ success = false, error = result })
    end
end)

--- NUI Callback: get nearby players
RegisterNUICallback("nui:property-gestion:getNearbyPlayers", function(_, cb)
    local playerList = {}
    local coords = GetEntityCoords(PlayerPedId())
    local nearbyPlayers = VFW.Game.GetPlayersInArea(coords, 5.0, {VFW.playerId})

    for _, playerId in ipairs(nearbyPlayers) do
        local serverId = GetPlayerServerId(playerId)
        if serverId and serverId > 0 then
            local name = TriggerServerCallback("dynasty:getPlayerName", serverId)
            table.insert(playerList, {
                serverId = serverId,
                name = name or ("Joueur #" .. serverId)
            })
        end
    end

    cb({ players = playerList })
end)

--- NUI Callback: add access (give key)
RegisterNUICallback("nui:property-gestion:addAccess", function(data, cb)
    TriggerServerEvent("vfw:property:giveAccess", data.serverId, VFW.ActualProperty)
    cb({})
end)

--- NUI Callback: remove access
RegisterNUICallback("nui:property-gestion:removeAccess", function(data, cb)
    TriggerServerEvent("vfw:property:removeAccess", VFW.ActualProperty, data.id)
    Wait(200)
    cb({})
end)

--- NUI Callback: refresh data after add/remove
RegisterNUICallback("nui:property-gestion:refreshData", function(_, cb)
    local gestionData = TriggerServerCallback("vfw:property:getGestion", VFW.ActualProperty)
    local perm = TriggerServerCallback("vfw:property:canManage", VFW.ActualProperty)
    VFW.PropertyCanManage = perm
    cb(gestionData or {})
end)

-- =============================================
-- Property Choice NUI callbacks
-- =============================================

RegisterNUICallback("nui:property-choice:select", function(data, cb)
    VFW.PropertyChoiceResult = data.choice
    VFW.Nui.Focus(false, false)
    cb({})
end)

RegisterNUICallback("nui:property-choice:close", function(_, cb)
    VFW.PropertyChoiceResult = "cancel"
    VFW.Nui.Focus(false, false)
    cb({})
end)

-- =============================================
-- Old property menu (kept for backward compat)
-- =============================================

local coOwnerList = {}
local open = false
--- .OpenGestionProperty
function VFW.OpenGestionProperty()
    open = not open
    VFW.Nui.Focus(open)
    VFW.Nui.HudVisible(not open)
    SendNUIMessage({
        action = "nui:property-menu:visible",
        data = open
    })
    if open then
        SetCursorLocation(0.5, 0.5)
        local propertyData = TriggerServerCallback("vfw:property:get", VFW.ActualProperty)
        if not propertyData then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous ne pouvez pas gérer cette propriété."
            })
            VFW.OpenGestionProperty()
        else
            SendNUIMessage({
                action = "nui:property-menu:data",
                data = propertyData
            })
        end
    end
end

RegisterNUICallback("nui:property-menu:close", function()
    if not open then
        return
    end

    VFW.OpenGestionProperty()
end)

RegisterNUICallback("nui:property-menu:save", function(data)
    if not open then
        return
    end

    VFW.OpenGestionProperty()
    TriggerServerEvent("vfw:property:save", VFW.ActualProperty, data)
end)
