---@meta _
---@diagnostic disable: duplicate-doc-field

--- MainMenuProps
---@return any
local function MainMenuProps()
    local data = {
        style = {
            menuStyle = "custom",
            bannerType = 1,
            gridType = 2,
            buyType = 0,
            backgroundType = 3,
            lineColor = "linear-gradient(to right, rgba(56, 220, 102, .6) 0%, rgba(16, 255, 108, .6) 56%, rgba(170, 219, 147, 0) 100%)",
            title = "DYNASTY",
        },
        eventName = "previewProperties",
        showStats = false,
        mouseEvents = false,
        color = { show = false },
        nameContainer = { show = false },
        headCategory = { show = false },
        category = { show = false },
        cameras = { show = false },
        items = {
            {
                label = 'HABITATIONS',
                model = 'Appartement',
                image = "assets/catalogues/habitation/Appartement.webp",
                style = "big"
            },
            {
                label = 'GARAGES',
                model = 'Garage',
                image = "assets/catalogues/habitation/Garage.webp",
                style = "big"
            },
            {
                label = 'ENTREPOTS',
                model = 'Entrepot',
                image = "assets/catalogues/habitation/Entrepot.webp",
                style = "big"
            }
        }
    }

    return data
end

---Get PropertyList
---@param category any
local function GetPropertyList(category)
    local data = {}

    for k, v in pairs(Property[category].data) do
        data[k] = {
            label = v.name,
            model = v.id,
            image = "assets/catalogues/habitation/preview/" .. v.id .. ".webp",
        }
    end

    return data
end

local index = {
    Appartement = 0,
    Garage = 1,
    Entrepot = 2
}

local actualProperty = nil
local lastCategory = nil

--- MenuProps
---@param cat any
---@return any
local function MenuProps(cat)

    local category = cat or "Appartement"
    local secondLabel = actualProperty and actualProperty.name or 'Nom du bien'

    local data = {
        style = {
            menuStyle = "custom",
            bannerType = 2,
            gridType = 3,
            buyType = 0,
            backgroundType = 1,
            bannerImg = "assets/catalogues/headers/header_dynasty.webp"
        },
        eventName = "previewMenuProperties",
        showStats = false,
        mouseEvents = true,
        color = { show = false },
        nameContainer = {
            show = (actualProperty ~= nil),
            top = false,
            firstLabel = "",
            secondLabel = secondLabel,
        },
        headCategory = {
            show = true,
            defaultIndex = index[category],
            items = {
                { id = "Appartement", label = "Habitations" },
                { id = "Garage", label = "Garages" },
                { id = "Entrepot", label = "Entrepots" }
            }
        },
        category = { show = false },
        cameras = { show = false },
        items = GetPropertyList(category)
    }
    return data
end

--- .OpenPreviewProperties
function VFW.OpenPreviewProperties()

    Wait(250)

    VFW.Nui.BigMenu(true, MainMenuProps())
end

RegisterNuiCallback("nui:newgrandcatalogue:previewProperties:selectGridType2", function(data)
    lastCategory = data
    VFW.Nui.UpdateBigMenu(MenuProps(data))
end)

RegisterNUICallback("nui:newgrandcatalogue:previewProperties:close", function()
    VFW.Nui.BigMenu(false)
    VFW.Cam:Destroy("previewHabitation")

    Wait(250)

end)

--- ClampCameraRotation
---@param rotX any
---@param rotY any
---@param rotZ any
---@return any
local function ClampCameraRotation(rotX, rotY, rotZ)
    local x = math.max(-90.0, math.min(90.0, rotX))
    local y = rotY % 360
    local z = rotZ % 360
    return vec3(x, y, z)
end

local rot
RegisterNuiCallback("nui:newgrandcatalogue:previewMenuProperties:mouseEvents", function(data)
    local cam = VFW.Cam:Get("previewHabitation")
    if cam then
        local x = rot.x - (0.3 * data.y)
        local z = rot.z - (0.3 * data.x)
        rot = ClampCameraRotation(x, rot.y, z)

        SetCamRot(cam, rot.x, rot.y, rot.z)
    end
end)

---Get PropertyById
---@param id number|string
---@return any
local function GetPropertyById(id)

    for k, v in pairs(Property) do
        for i = 1, #v.data do
            if v.data[i].id == id then
                return v.data[i] 
            end
        end
    end

    return false
end

local id = 0
RegisterNuiCallback("nui:newgrandcatalogue:previewMenuProperties:selectGridType3", function(data)
    actualProperty = GetPropertyById(data)
    if not actualProperty then
        return
    end

    id += 1
    local currentId = id
    DoScreenFadeOut(250)
    Wait(250)
    if currentId ~= id then
        return
    end

    SetFocusArea(actualProperty.cam.CamCoords.x, actualProperty.cam.CamCoords.y, actualProperty.cam.CamCoords.z)
    Wait(1000)
    if currentId ~= id then
        return
    end

    if actualProperty.ipl then
    actualProperty.ipl()
    else
        PinInteriorInMemory(GetInteriorAtCoords(actualProperty.cam.CamCoords.x, actualProperty.cam.CamCoords.y, actualProperty.cam.CamCoords.z))
    end

    Wait(500)
    if currentId ~= id then
        return
    end

    if VFW.Cam:Get("previewHabitation") then
        VFW.Cam:Update("previewHabitation", actualProperty.cam)
    else
        VFW.Cam:Create("previewHabitation", actualProperty.cam)
    end

    rot = actualProperty.cam.CamRot
    DoScreenFadeIn(250)
    VFW.Nui.UpdateBigMenu(MenuProps(lastCategory))
end)

RegisterNUICallback("nui:newgrandcatalogue:previewMenuProperties:selectHeadCategory", function(data)
    lastCategory = data
    VFW.Nui.UpdateBigMenu(MenuProps(data))
end)

RegisterNUICallback("nui:newgrandcatalogue:previewMenuProperties:close", function()
    VFW.Nui.BigMenu(false)
    id += 1
    if VFW.Cam:Get("previewHabitation") then
        id += 1
        DoScreenFadeOut(250)
        Wait(250)
        VFW.Cam:Destroy("previewHabitation")
        ClearFocus()
        Wait(500)
        DoScreenFadeIn(500)
    end

    Wait(250)

end)
