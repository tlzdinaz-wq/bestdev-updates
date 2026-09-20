---@meta _
---@diagnostic disable: duplicate-doc-field

---Create JobInvoince
---@return number|table|boolean Created object or success status
function CreateJobInvoince()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
        return
    end
end

-- Property management points removed — all management is done via the Dynasty tablet

local function loadPropertiesEdit() end
local function unloadPropertiesEdit() end

CreateJobAdvert = function()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
        return
    end

    VFW.Nui.AnnounceEntreprise(true)
end

---Set JobDuty
function SetJobDuty()
    VFW.ChangeDuty(not VFW.PlayerData.job.onDuty)
    if VFW.PlayerData.job.onDuty then
        if VFW.PlayerData.job.name == "dynasty" then
            loadPropertiesEdit()
        end

        VFW.ShowNotification({
            type = 'VERT',
            content = "Vous êtes maintenant en service."
        })
    else
        if VFW.PlayerData.job.name == "dynasty" then
            unloadPropertiesEdit()
        end

        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'êtes plus en service."
        })
    end
end

--- OpenInvoice
function OpenInvoice(targetId)
    TriggerEvent("vfw:radial:open:invoice", targetId)
end

--- OpenPropertyCreationMenu
---@return any
function OpenPropertyCreationMenu()
    if not VFW.PlayerData.job.onDuty then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
        return
    end

    VFW.Nui.Radial(nil,false)
    radialOpen = false
    VFW.CreateProperty()
end

---Get PropertyList
local function GetPropertyList()
    local properties = {}

    for i = 1, #Property.Garage.data do
        local property = Property.Garage.data[i]
        table.insert(properties, {
            type = "Garage",
            name = property.name,
            img = property.id
        })  
    end

    for i = 1, #Property.Appartement.data do
        local property = Property.Appartement.data[i]
        table.insert(properties, {
            type = "Habitations",
            name = property.name,
            img = property.id
        })  
    end

    for i = 1, #Property.Entrepot.data do
        local property = Property.Entrepot.data[i]
        table.insert(properties, {
            type = "Entrepot",
            name = property.name,
            img = property.id
        })  
    end

    return properties
end

local openEdit = false
local idProperty = 0
--- .OpenPropertyEdit
---@param id number|string
function VFW.OpenPropertyEdit(id)
    openEdit = not openEdit
    VFW.Nui.Focus(openEdit, false)
    VFW.Nui.HudVisible(not openEdit)
    SendNUIMessage({
        action = "nui:habitation-menu:visible",
        data = openEdit
    })
    if openEdit then
        SetCursorLocation(0.5, 0.5)
        local property = TriggerServerCallback("vfw:job:dynasty:getProperty", id)
        idProperty = id
        local endOwner, _ = string.find(property.owner, ":")
        SendNUIMessage({
            action = "nui:habitation-menu:data",
            data = {    
                type = "Gestion",
                name = property.name,
                access = property.state,
                ownerType = string.sub(property.owner, 1, (endOwner or 2)-1), 
            }
        })
    else
        idProperty = 0
    end
end

RegisterNUICallback("nui:habitation-menu:transfert", function()
    if not openEdit then
        return
    end

    local propertyId = idProperty
    VFW.OpenPropertyEdit()

    local playerId = VFW.StartSelect(5.0, true)
    if not playerId then
        return
    end

    TriggerServerEvent("vfw:job:dynasty:transfert", propertyId, GetPlayerServerId(playerId))
end)

RegisterNUICallback("nui:habitation-menu:double", function()
    if not openEdit then
        return
    end

    local propertyId = idProperty
    VFW.OpenPropertyEdit()

    local playerId = VFW.StartSelect(5.0, true)
    if not playerId then
        return
    end

    TriggerServerEvent("vfw:job:dynasty:giveKey", propertyId, GetPlayerServerId(playerId))
end)

RegisterNUICallback("nui:habitation-menu:confirm", function(data)
    if not openEdit then
        return
    end

    TriggerServerCallback("vfw:job:dynasty:propertyUpdate", idProperty, data)
    VFW.OpenPropertyEdit()
end)

RegisterNUICallback("nui:habitation-menu:delete", function()
    if not openEdit then
        return
    end

    local propertyId = idProperty
    VFW.OpenPropertyEdit()
    local validations = VFW.Nui.KeyboardInput(true, "Confimer 'OUI'")

    if string.lower(validations) == "oui" then
        TriggerServerEvent("vfw:job:dynasty:deleteProperty", propertyId)

        VFW.ShowNotification({
            type = 'VERT',
            content = "Vous venez de supprimer la propriété."
        })
    else
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous n'avez pas confirmé."
        })
    end
end)

RegisterNUICallback("nui:habitation-menu:copro", function()
    if not openEdit then
        return
    end

    local propertyId = idProperty
    VFW.OpenPropertyEdit()
    idProperty = propertyId
    VFW.OpenGestionCoowner()
end)

local openCopro = false
--- .OpenGestionCoowner
---@param idPropertyTemp number|string
function VFW.OpenGestionCoowner(idPropertyTemp)
    if idProperty then
        idProperty = idPropertyTemp
    end

    openCopro = not openCopro
    VFW.Nui.Focus(openCopro, false)
    VFW.Nui.HudVisible(not openCopro)
    SendNUIMessage({
        action = "nui:property-menu:visible",
        data = openCopro
    })
    if openCopro then
        SetCursorLocation(0.5, 0.5)
        local propertyData = TriggerServerCallback("vfw:job:dynasty:coowner", idProperty)
        SendNUIMessage({
            action = "nui:property-menu:dataCoowner",
            data = propertyData
        })
    else
        idProperty = 0
    end
end

RegisterNUICallback("nui:property-menu:return", function(id)
    if not openCopro then
        return
    end

    TriggerServerEvent("vfw:job:dynasty:save", idProperty, id)
    VFW.OpenGestionCoowner()
end)

RegisterNUICallback("nui:property-menu:close", function()
    if not openCopro then
        return
    end

    VFW.OpenGestionCoowner()
end)

local open = false
---Create VFW.Property
function VFW.CreateProperty()
    open = not open
    VFW.Nui.Focus(open)
    VFW.Nui.HudVisible(not open)
    SendNUIMessage({
        action = "nui:habitation-menu:visible",
        data = open
    })
    if open then
        SetCursorLocation(0.5, 0.5)
        SendNUIMessage({
            action = "nui:habitation-menu:data",
            data = {
                type = "Creation",
                duration = 1,
                maxLocationJours = 30,
                items = GetPropertyList(),
                durationProlongation = 1
            }
        })
    else
        VFW.ClosePropertyPreview()
    end
end

RegisterNUICallback("nui:habitation-menu:close", function()
    if open then
        VFW.CreateProperty()
    elseif openEdit then
        VFW.OpenPropertyEdit()
    end
end)

RegisterNUICallback("nui:habitation-menu:create", function(data)
    if not open then
        return
    end

    VFW.CreateProperty()
    local pos = GetEntityCoords(VFW.PlayerData.ped)
    data.pos = { x = pos.x, y = pos.y, z = pos.z, w = GetEntityHeading(VFW.PlayerData.ped) }
    TriggerServerEvent("vfw:job:dynasty:createProperty", data)
end)

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

local id = 0
RegisterNUICallback("nui:habitation-menu:selectedItems", function(data)
    if not open then
        return
    end

    local property = GetPropertyByName(data.items)
    if not property then
        return
    end

    id += 1
    local currentId = id
    DoScreenFadeOut(250)
    Wait(250)
    if currentId ~= id then
        return
    end

    SetFocusArea(property.cam.CamCoords.x, property.cam.CamCoords.y, property.cam.CamCoords.z)
    Wait(1000)
    if currentId ~= id then
        return
    end

    if property.ipl then
        property.ipl()
    else
        PinInteriorInMemory(GetInteriorAtCoords(property.cam.CamCoords.x, property.cam.CamCoords.y, property.cam.CamCoords.z))
    end

    Wait(500)
    if currentId ~= id then
        return
    end

    if VFW.Cam:Get("previewHabitation") then
        VFW.Cam:Update("previewHabitation", property.cam)
    else
        VFW.Cam:Create("previewHabitation", property.cam)
    end

    DoScreenFadeIn(250)
end)

RegisterNUICallback("nui:habitation-menu:disablePreview", function()
    if not open then
        return
    end

    VFW.ClosePropertyPreview()
end)

--- .ClosePropertyPreview
function VFW.ClosePropertyPreview()
    if VFW.Cam:Get("previewHabitation") then
        id += 1
        DoScreenFadeOut(250)
        Wait(250)
        VFW.Cam:Destroy("previewHabitation")
        ClearFocus()
        Wait(500)
        DoScreenFadeIn(500)
    end
end