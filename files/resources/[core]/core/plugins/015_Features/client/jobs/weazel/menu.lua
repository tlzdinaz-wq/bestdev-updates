---@meta _
---@diagnostic disable: duplicate-doc-field

local props = {}

--- SpawnProps
---@param object any
---@param name string
local function SpawnProps(object, name)
    local playerPed = VFW.PlayerData.ped
    local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
    local objCoords = coords + forward * 2.5
    local heading = GetEntityHeading(playerPed)
    local isPlaced = false
    
    local objectSpawn = VFW.OneSync.CreateObject(object, objCoords)
    SetEntityHeading(objectSpawn, heading)
    PlaceObjectOnGroundProperly(objectSpawn)
    SetEntityCollision(objectSpawn, false, false)
    SetEntityAlpha(objectSpawn, 150, false)
    
    local networkId = ObjToNet(objectSpawn)
    SetNetworkIdExistsOnAllMachines(networkId, true)
    NetworkRegisterEntityAsNetworked(objectSpawn)
    SetNetworkIdCanMigrate(networkId, true)
    
    while not isPlaced do
        coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
        objCoords = coords + forward * 2.5
        SetEntityCoords(objectSpawn, objCoords.x, objCoords.y, objCoords.z, false, false, false, true)
        PlaceObjectOnGroundProperly(objectSpawn)
        
        if IsControlPressed(0, 190) then
            heading = heading + 1.0
        elseif IsControlPressed(0, 189) then
            heading = heading - 1.0
        end
        
        SetEntityHeading(objectSpawn, heading)
        
        VFW.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour placer l'objet\n~INPUT_FRONTEND_LEFT~ ou ~INPUT_FRONTEND_RIGHT~ pour faire pivoter l'objet")
        
        if VFW.Interact.JustPressed(0, 38) then
            isPlaced = true
        end

        DisableControlAction(0, 22, true)

        Wait(0)
    end

    SetEntityCollision(objectSpawn, true, true)
    SetEntityInvincible(objectSpawn, true)
    FreezeEntityPosition(objectSpawn, true)
    ResetEntityAlpha(objectSpawn)

    table.insert(props, {prop = objectSpawn, nom = name})
    
    return networkId
end

local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/f5.png")
local mainmenu = VUI:CreateMenu("Menu Props", defaultBanner, true)
local submenu = VUI:CreateSubMenu(mainmenu, "Menu Props", defaultBanner, true)

--- BuildMenuSub
local function BuildMenuSub()

    for propIndex,propData in pairs(props) do
        submenu.Button(propData.nom, nil, nil, "chevron", false, function()
            DeleteEntity(propData.prop)
            table.remove(props, propIndex)
            submenu.refresh()
        end)
    end
end

--- BuildMenuMain
local function BuildMenuMain()
    mainmenu.Button("Supprimer mes props", nil, nil, "chevron", false, function()
    end, submenu)

    mainmenu.Separator(nil)

    mainmenu.Button("Fond vert", nil, nil, "chevron", false, function()
        SpawnProps("prop_ld_greenscreen_01", "Fond vert")
    end)

    mainmenu.Button("Caméra fixe", nil, nil, "chevron", false, function()
        SpawnProps("prop_tv_cam_02", "Caméra fixe")
    end)

    mainmenu.Button("Caméra épaule", nil, nil, "chevron", false, function()
        SpawnProps("prop_v_cam_01", "Caméra épaule")
    end)

    mainmenu.Button("Lampe 1", nil, nil, "chevron", false, function()
        SpawnProps("prop_worklight_03a", "Lampe 1")
    end)

    mainmenu.Button("Lampe 2", nil, nil, "chevron", false, function()
        SpawnProps("prop_worklight_03b", "Lampe 2")
    end)

    mainmenu.Button("Lampe 3", nil, nil, "chevron", false, function()
        SpawnProps("prop_worklight_04c_l1", "Lampe 3")
    end)

    mainmenu.Button("Lampe 4", nil, nil, "chevron", false, function()
        SpawnProps("prop_worklight_04b_l1", "Lampe 4")
    end)
end

mainmenu.OnOpen(function()
    BuildMenuMain()
end)

submenu.OnOpen(function()
    BuildMenuSub()
end)

--- OpenMenuPropsWeazel
---@return any
function OpenMenuPropsWeazel()
    if not VFW.PlayerData.job.onDuty then 
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous devez être en service pour accéder à cette fonctionnalité."
        })
        return 
    end

    mainmenu.toggle()
end
