---@meta _
---@diagnostic disable: duplicate-doc-field

local lastJob = nil
local lastZone = {}
local lastBlip = {}
local lastVehicle = nil
local VUI = exports["VUI"]
local defaultBanner = VFW.CDN.Get("banners/f5.png")

---Create Zone
---@param name string
---@param positions vector3|table Position
---@param interactLabel string
---@param interactKey any
---@param interactIcons any
---@param action any
---@param colors any
---@return number|table|boolean Created object or success status
local function createZone(name, positions, interactLabel, interactKey, interactIcons, action, colors)
    local zone = Worlds.Zone.Create(positions, 2, false, function()
        if action.onEnter then
            action.onEnter()
        end

        if action.onPress then
            VFW.RegisterInteraction(name, action.onPress)
        end

    end, function()
        VFW.RemoveInteraction(name)
        if action.onExit then
            action.onExit()
        end

    end, interactLabel, interactKey, interactIcons, colors)

    return zone
end

---Create Blip
---@param coords vector3|table Coordinates
---@param sprite any
---@param color any
---@param scale any
---@param name string
---@return number|table|boolean Created object or success status
local function createBlip(coords, sprite, color, scale, name)
    local blips = AddBlipForCoord(coords)
    SetBlipSprite(blips, sprite)
    SetBlipScale(blips, scale)
    SetBlipColour(blips, color)
    SetBlipAsShortRange(blips, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blips)
    return blips
end

---Load MenuCustom
local function loadMenuCustom()

    while not VFW.Jobs or not VFW.Jobs.Menu or not VFW.Jobs.Menu.CustomFaction do
        Wait(100)
    end

    while not next(VFW.Jobs.Menu.CustomFaction) do
        Wait(100)
    end

    if not lastJob or not VFW.Jobs.Menu.CustomFaction[lastJob] then
        return
    end

    local config = VFW.Jobs.Menu.CustomFaction[lastJob]
    local banner = "menu_title_" .. lastJob

    if lastJob == "lspd" then
        banner = "menu_title_police"
    elseif IsPoliceJob and IsPoliceJob(lastJob) then
        -- sasp / saspsud / saspnord / autres jobs police
        banner = "menu_title_" .. lastJob
    end

    local main_custom_menu = VUI:CreateMenu("Custom", defaultBanner, true)
    local liveries_custom_menu = VUI:CreateSubMenu(main_custom_menu, "Motif", defaultBanner, true)
    local stickers_custom_menu = VUI:CreateSubMenu(main_custom_menu, "tickers", defaultBanner, true)
    local extra_custom_menu = VUI:CreateSubMenu(main_custom_menu, "Extra", defaultBanner, true)
    local color_custom_menu = VUI:CreateSubMenu(main_custom_menu, "Couleur", defaultBanner, true)

--- BuildMenuLiveries
    local function BuildMenuLiveries()
        if GetNumVehicleMods(lastVehicle, 48) == 0 then
            liveries_custom_menu.Separator("Pas de modification disponible")
        else
            for i = 0, GetNumVehicleMods(lastVehicle, 48) - 1 do
                local name = GetLabelText(GetModTextLabel(lastVehicle, 48, i))

                if name == "NULL" then
                    name = "Original"
                end

                liveries_custom_menu.Button(name, nil, nil, "chevron", false, function()
                    SetVehicleMod(lastVehicle, 48, i, 0)
                    liveries_custom_menu.refresh()
                end)
            end
        end
    end

--- BuildMenuStickers
    local function BuildMenuStickers()
        if GetVehicleLiveryCount(lastVehicle) <= 0 then
            stickers_custom_menu.Separator("Pas de modification disponible")
        else
            for i = 0, GetVehicleLiveryCount(lastVehicle) - 1 do
                local name = GetLabelText(GetLiveryName(lastVehicle, i))

                if name == "NULL" then
                    name = "Original"
                end

                stickers_custom_menu.Button(name, nil, nil, "chevron", false, function()
                    SetVehicleLivery(lastVehicle, i)
                    stickers_custom_menu.refresh()
                end)
            end
        end
    end

--- BuildMenuExtra
    local function BuildMenuExtra()
        local availableExtras = {}
        local extrasExist = false

        for extra = 0, 20 do
            if DoesExtraExist(lastVehicle, extra) then
                availableExtras[extra] = extra
                extrasExist = true
            end
        end

        if not extrasExist then
            extra_custom_menu.Separator("Pas de modification disponible")
        else
            for i in pairs(availableExtras) do
                extra_custom_menu.Button("EXTRA : " .. i, nil, nil, "chevron", false, function()
                    if IsVehicleExtraTurnedOn(lastVehicle, i) then
                        SetVehicleExtra(lastVehicle, i, 1)
                    else
                        SetVehicleExtra(lastVehicle, i, 0)
                    end

                    extra_custom_menu.refresh()
                end)
            end
        end
    end

--- BuildMenuColor
    local function BuildMenuColor()
        local colorOptions = {
            { name = "Noir",         color = 0 },
            { name = "Blanc",        color = 111 },
            { name = "Violet",       color = 149 },
            { name = "Jaune",        color = 42 },
            { name = "Argent Ombré", color = 7 },
            { name = "Rouge",        color = 27 },
            { name = "Bleu",         color = 75 },
            { name = "Vert",         color = 49 },
            { name = "Brun clair",   color = 98 },
        }

        for _, colorData in pairs(colorOptions) do
            local name = colorData.name
            local color = colorData.color

            color_custom_menu.Button(name, nil, nil, "chevron", false, function()
                SetVehicleColours(lastVehicle, color, color)
                color_custom_menu.refresh()
            end)
        end
    end

--- BuildMenuMain
    local function BuildMenuMain()
        main_custom_menu.Button("Motif", nil, nil, "chevron", false, function() end, liveries_custom_menu)
        main_custom_menu.Button("Stickers", nil, nil, "chevron", false, function() end, stickers_custom_menu)
        main_custom_menu.Button("Extra", nil, nil, "chevron", false, function() end, extra_custom_menu)
        main_custom_menu.Button("Couleur", nil, nil, "chevron", false, function() end, color_custom_menu)
    end

    main_custom_menu.OnOpen(function()
        main_custom_menu.ClearItems()
        BuildMenuMain()
    end)

    liveries_custom_menu.OnOpen(function()
        liveries_custom_menu.ClearItems()
        BuildMenuLiveries()
    end)

    stickers_custom_menu.OnOpen(function()
        stickers_custom_menu.ClearItems()
        BuildMenuStickers()
    end)

    extra_custom_menu.OnOpen(function()
        extra_custom_menu.ClearItems()
        BuildMenuExtra()
    end)

    color_custom_menu.OnOpen(function()
        color_custom_menu.ClearItems()
        BuildMenuColor()
    end)

    main_custom_menu.OnClose(function()
        FreezeEntityPosition(lastVehicle, false)
    end)

--- OpenCustomMenu
    local function OpenCustomMenu()
        main_custom_menu.toggle()
    end

--- .Jobs.Menu.MenuCustom
---@param veh any
---@return any
    function VFW.Jobs.Menu.MenuCustom(veh)
        if not VFW.PlayerData.job.perms[VFW.PlayerData.job.grade_name].custom then
            return VFW.ShowNotification({
                type = "ROUGE",
                content = "Vous n'avez pas la permission d'utiliser ce menu.",
            })
        end

        local jn = VFW.PlayerData.job.name
        local bannerKey
        if jn == "lspd" then
            bannerKey = "menu_title_police"
        elseif jn == "lssd" then
            bannerKey = "menu_title_lssd"
        elseif jn == "sams_pib" or jn == "sams_pab" then
            bannerKey = "menu_title_ems"
        elseif jn == "lsfd" then
            bannerKey = "menu_title_lsfd"
        elseif jn == "usss" then
            bannerKey = "menu_title_usss"
        elseif IsPoliceJob and IsPoliceJob(jn) then
            -- sasp / saspsud / saspnord / autres jobs police
            bannerKey = "menu_title_" .. jn
        end

        if bannerKey then
            main_custom_menu.ChangeBanner(bannerKey)
            liveries_custom_menu.ChangeBanner(bannerKey)
            stickers_custom_menu.ChangeBanner(bannerKey)
            extra_custom_menu.ChangeBanner(bannerKey)
            color_custom_menu.ChangeBanner(bannerKey)
            OpenCustomMenu()
        end

        lastVehicle = veh
        FreezeEntityPosition(lastVehicle, true)
    end

---@class lastZone
    lastZone = {}
---@class lastBlip
    lastBlip = {}

    for _, pedData in ipairs(config.Point.Ped) do
        for _, coord in ipairs(pedData.coords) do
            local coords = vector(coord.x, coord.y, coord.z + 1.25)
            lastBlip[#lastBlip + 1] = createBlip(coords, pedData.blip.sprite, pedData.blip.color, pedData.blip.scale, pedData.blip.label)
            lastZone[#lastZone + 1] = createZone(
                    pedData.zone.name,
                    coords,
                    pedData.zone.interactLabel,
                    pedData.zone.interactKey,
                    pedData.zone.interactIcons,
                    { onPress = pedData.zone.onPress }
            )
            Wait(25)
        end
    end
end

--- deletingZone
local function deletingZone()

    for i, zone in ipairs(lastZone) do
        if zone then
            Worlds.Zone.Remove(zone)
            lastZone[i] = nil
        end
    end

    VFW.RemoveInteraction(("menu_custom_%s"):format(lastJob))

---@class lastZone
    lastZone = {}
end

--- deletingBlip
local function deletingBlip()

    for i, blip in ipairs(lastBlip) do
        if blip then
            RemoveBlip(blip)
            lastBlip[i] = nil
        end
    end

---@class lastBlip
    lastBlip = {}
end

---@param Job table Job data
RegisterNetEvent("vfw:setJob", function(Job)
    if Job.name == lastJob then
        return
    end

    deletingZone()
    deletingBlip()
    if Job.name == "unemployed" then
        lastJob = nil
        return
    end

    lastJob = Job.name
    Wait(5000)
    loadMenuCustom()
end)

RegisterNetEvent("vfw:playerReady", function()
    if lastJob then
        deletingZone()
        deletingBlip()
        lastJob = nil
    end

    if VFW.PlayerData.job.name == "unemployed" then
        return
    end

    lastJob = VFW.PlayerData.job.name
    Wait(5000)
    loadMenuCustom()
end)
