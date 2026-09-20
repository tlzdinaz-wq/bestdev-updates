---@meta _
---@diagnostic disable: duplicate-doc-field

--local interactionZones = {}
--
--CreateThread(function()
--    while not VFW.PlayerLoaded do
--        Wait(100)
--    end
--
--    for key, value in pairs(Config.Features.Masque) do
--        -- Obtenemos la posición (asumiendo que usas el primer índice del valor)
--        local firstCOH = value[1].COH
--
--        -- Llamamos a tu función centralizada de interacción
--        CreateMarkerAndInteraction(
--                firstCOH,
--                "Magasin de masque",
--                "Appuyez sur ~INPUT_CONTEXT~ pour accéder aux ~y~Masques~s~.",
--                function()
--                    -- Lógica al presionar E
--                    TriggerEvent('skinchanger:getSkin', function(skin)
--                        -- Verificamos si es hombre (0) o mujer (1)
--                        if skin.sex == 0 or skin.sex == 1 then
--                            -- Posicionar al jugador frente al mostrador
--                            SetEntityCoords(PlayerPedId(), firstCOH.x, firstCOH.y, firstCOH.z - 1.0)
--                            SetEntityHeading(PlayerPedId(), firstCOH.w)
--
--                            -- Abrir el menú de máscaras
--                            LoadMask(value)
--                        else
--                            -- Notificación en caso de ser un Ped
--                            VFW.ShowNotification({
--                                type = "ROUGE",
--                                content = "Les peds ne peuvent pas utiliser le magasin de masque.",
--                            })
--                        end
--                    end)
--                end
--        )
--    end
--
--    --TODO: Good coords
--    --for key, value in pairs(Config.Features.Location) do
--    --    VFW.CreateBlipAndPoint("location", vector3(v.Ped.x, v.Ped.y, v.Ped.z + 1.25), k, 595, 3, 0.8, "Location de véhicules",  "Location", "E", "Location",{
--    --        onPress = function()
--    --            LoadLocation(v)
--    --        end
--    --    })
--    --end
--
--    function CreateMarkerAndInteraction(pos, title, helpText, action)
--        -- Crear el Blip (opcional, si quieres el icono en el mapa)
--        VFW.CreateBlipInternal({pos = vector3(pos.x, pos.y, pos.z)}, 73, 8, 0.8, title)
--
--        -- Guardar la zona para el hilo principal
--        table.insert(interactionZones, {
--            pos = pos,
--            helpText = helpText,
--            action = action
--        })
--    end
--
--    -- Único hilo que procesa todas las marcas registradas
--    Citizen.CreateThread(function()
--        while true do
--            local sleep = 1000
--            local playerCoords = GetEntityCoords(PlayerPedId())
--
--            -- Si el menú no está abierto (ajusta 'cams' según tu script)
--            if not cams then
--                for _, zone in ipairs(interactionZones) do
--                    local dist = #(playerCoords - vector3(zone.pos.x, zone.pos.y, zone.pos.z))
--
--                    if dist < 5.0 then
--                        sleep = 0
--                        -- Dibujar el círculo plano en el suelo
--                        DrawMarker(25, zone.pos.x, zone.pos.y, zone.pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 139, 106, 34, 150, false, false, 2, false, nil, nil, false)
--
--                        if dist < 1.5 then
--                            BeginTextCommandDisplayHelp("STRING")
--                            AddTextComponentSubstringPlayerName(zone.helpText)
--                            EndTextCommandDisplayHelp(0, false, true, -1)
--
--                            if VFW.Interact.JustPressed(1, 38) then
--                                zone.action()
--                            end
--                        end
--                    end
--                end
--            end
--            Wait(sleep)
--        end
--    end)
--
--   --TODO: Merge the clothe shops
--   -- for key, value in pairs(Config.Features.Binco) do
--   --     for _, pos in ipairs(value.Pos) do
--   --         VFW.CreateBlipAndPoint("binco", vector3(pos.x, pos.y, pos.z), key, 73, 8, 0.8, "Boutique de vêtements", value.Title, "E", "Binco", {
--   --             onPress = function()
--   --                 SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--   --                 SetEntityHeading(VFW.PlayerData.ped, pos.w)
--   --                 LoadPreBinco(value.Cam)
--   --             end
--   --         })
--   --     end
--   -- end
--
--    for key, value in pairs(Config.Features.Binco) do
--        for _, pos in ipairs(value.Pos) do
--            -- Llamamos a nuestra función centralizada
--            CreateMarkerAndInteraction(
--                    pos,
--                    value.Title,
--                    "Appuyez sur ~INPUT_CONTEXT~ pour accéder au ~y~Binco~s~.",
--                    function()
--                        -- Lógica al presionar E
--                        SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--                        SetEntityHeading(VFW.PlayerData.ped, pos.w)
--
--                        -- Llamada a la tienda
--                        LoadPreBinco(value.Cam)
--                    end
--            )
--        end
--    end
--
--    --for key, value in pairs(Config.Features.Ponsobys) do
--    --    for _, pos in ipairs(value.Pos) do
--    --        VFW.CreateBlipAndPoint("ponsobys", vector3(pos.x, pos.y, pos.z), key, 73, 8, 0.8, "Boutique de vêtements", value.Title, "E", "Binco", {
--    --            onPress = function()
--    --                SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--    --                SetEntityHeading(VFW.PlayerData.ped, pos.w)
--    --                LoadPreBinco(value.Cam)
--    --            end
--    --        })
--    --    end
--    --end
--    --
--    --for key, value in pairs(Config.Features.Suburban) do
--    --    for _, pos in ipairs(value.Pos) do
--    --        VFW.CreateBlipAndPoint("suburban", vector3(pos.x, pos.y, pos.z), key, 73, 8, 0.8, "Boutique de vêtements", value.Title, "E", "Binco", {
--    --            onPress = function()
--    --                SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--    --                SetEntityHeading(VFW.PlayerData.ped, pos.w)
--    --                LoadPreBinco(value.Cam)
--    --            end
--    --        })
--    --    end
--    --end
--
--    -- Bucle para PONSOBYS
--    for key, value in pairs(Config.Features.Ponsobys) do
--        for _, pos in ipairs(value.Pos) do
--            CreateMarkerAndInteraction(
--                    pos,
--                    value.Title,
--                    "Appuyez sur ~INPUT_CONTEXT~ pour accéder a ~y~Ponsonbys~s~.",
--                    function()
--                        SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--                        SetEntityHeading(VFW.PlayerData.ped, pos.w)
--                        LoadPreBinco(value.Cam)
--                    end
--            )
--        end
--    end
--
--    -- Bucle para SUBURBAN
--    for key, value in pairs(Config.Features.Suburban) do
--        for _, pos in ipairs(value.Pos) do
--            CreateMarkerAndInteraction(
--                    pos,
--                    value.Title,
--                    "Appuyez sur ~INPUT_CONTEXT~ pour accéder a ~y~Suburban~s~.",
--                    function()
--                        SetEntityCoords(VFW.PlayerData.ped, pos.x, pos.y, pos.z - 1)
--                        SetEntityHeading(VFW.PlayerData.ped, pos.w)
--                        LoadPreBinco(value.Cam)
--                    end
--            )
--        end
--    end
--
--    -- for k, v in pairs(Config.Features.GaragePublic) do
--    --     VFW.CreateBlipAndPoint("garage", v.Public, k, 524, 48, 0.8, "Garage", "Garage", "E", "Garage",{
--    --         onPress = function()
--    --             local vehicle = GetVehiclePedIsIn(VFW.PlayerData.ped, false)
--    --             if vehicle and (vehicle ~= 0) then
--    --                 if (GetPedInVehicleSeat(vehicle, -1) == VFW.PlayerData.ped) and Entity(vehicle).state.VehicleProperties then
--    --                     local result = TriggerServerCallback("vfw:vehicleGaragePublic", Entity(vehicle).state.VehicleProperties.plate, VFW.Game.GetVehicleProperties(vehicle))
--
--    --                     if not result then
--    --                         return
--    --                     end
--    --                 else
--    --                     xPlayer.showNotification({
--    --                         type = 'ILLEGAL',
--    --                         name = "GARAGE",
--    --                         label = "REFUSÉ",
--    --                         labelColor = "#5A0606",
--    --                         mainColor = 'rouge',
--    --                         logo = "https://ih1.redbubble.net/image.875935494.5004/st,small,507x507-pad,600x600,f8f8f8.webp",
--    --                         mainMessage = "Vous n'êtes pas le propriétaire du véhicule ou pas conducteur.",
--    --                         duration = 10,
--    --                     })
--    --                     return
--    --                 end
--    --             end
--
--    --             VFW.OpenGaragePublic(v)
--    --         end
--    --     })
--    -- end
--
--    -- for key, value in pairs(Config.Features.Pound) do
--    --     VFW.CreateBlipAndPoint("pound", value.Public, key, 50, 5, 0.8, "Fourriere", "Fourriere", "E", "Fourrière",{
--    --         onPress = function()
--    --             VFW.OpenPound(v)
--    --         end
--    --     })
--    -- end
--

    --VFW.CreateBlipAndPoint("dynasty", Config.Features.Dynasty.pos - vector3(0, 0, -1), "dynasty", 374, 0, 0.8, "Dynasty", "Propriété", "E", "Dynasty",{
    --    onPress = function()
    --        SetEntityCoords(VFW.PlayerData.ped, -704.2142333984375, 269.3979187011719, 83.14735412597656 - 1)
    --        SetEntityHeading(VFW.PlayerData.ped, 274.460693359375)
    --        VFW.OpenDynastyTabletFromPoint()
    --    end
    --})
--
--    --TODO: Good coords
--    --for key, value in pairs(Config.Features.Tattoo) do
--    --    for _, pos in ipairs(value.Pos) do
--    --        VFW.CreateBlipAndPoint("tattoo", vector3(pos.x, pos.y, pos.z), key, 75, 0, 0.8, "Salon de tatouage", "Tatouage", "E", "Tatouage", {
--    --            onPress = function()
--    --                TriggerEvent('skinchanger:getSkin', function(skin)
--    --                    if skin.sex == 0 or skin.sex == 1 then
--    --                        SetEntityHeading(VFW.PlayerData.ped, pos.w)
--    --                        LoadTattoo(value.Cam)
--    --                    else
--    --                        VFW.ShowNotification({
--    --                            type = "ROUGE",
--    --                            content = "Les peds ne peuvent pas utiliser le salon de tatouage.",
--    --                        })
--    --                    end
--    --                end)
--    --            end
--    --        })
--    --    end
--    --end
--
--    --TODO: Good coords
--    --for key, value in pairs(Config.Features.Bike) do
--    --    VFW.CreateBlipAndPoint("bike", vector3(value.Ped.x, value.Ped.y, value.Ped.z + 1.25), key, 226, 23, 0.8, "Magasin de skate",  "PRO Bikes", "E", "Catalogue",{
--    --        onPress = function()
--    --            cEntity.Visual.HideAllEntities(true)
--    --            VFW.skateShop.Load(v)
--    --        end
--    --    })
--    --end
--
--    --TODO: Good coords
--    --for key, value in pairs(Config.Features.SheNails) do
--    --    local firstCOH = value[1].COH
--    --
--    --    VFW.CreateBlipAndPoint("shenails", vector3(firstCOH.x, firstCOH.y, firstCOH.z), key, 279, 8, 0.8, "SheNails",  "SheNails", "E", "Catalogue",{
--    --        onPress = function()
--    --            TriggerEvent('skinchanger:getSkin', function(skin)
--    --                if skin.sex == 0 or skin.sex == 1 then
--    --                    SetEntityCoords(VFW.PlayerData.ped, firstCOH.x, firstCOH.y, firstCOH.z - 1)
--    --                    SetEntityHeading(VFW.PlayerData.ped, firstCOH.w)
--    --                    LoadSheNails(v)
--    --                else
--    --                    VFW.ShowNotification({
--    --                        type = "ROUGE",
--    --                        content = "Les peds ne peuvent pas utiliser le shenails.",
--    --                    })
--    --                end
--    --            end)
--    --        end
--    --    })
--    --end
--
--    --for _, elevator in ipairs(Config.Features.Elevators) do
--    --    for key, entry in ipairs(elevator.entries) do
--    --        VFW.CreateBlipAndPoint("elevator", vector3(entry.pos.x, entry.pos.y, entry.pos.z + 1.0), key, nil, nil, nil, nil, "Ascenseur", "E", "Ascenseur", {
--    --            onPress = function()
--    --                OpenMenuElevator(elevator, entry.floor)
--    --            end
--    --        })
--    --    end
--    --end
--
--    --VFW.CreatePed(vector4(-268.698, -956.209, 30.223, 208.359), "cs_bankman")
--
--    --VFW.CreateBlipAndPoint("jobcenter", vector3(-268.698, -956.209, 30.223 + 0.75), "jobcenter", 590, 2, 0.8, "Job center", "Job center", "E", "Jobcenter",{
--    --    onPress = function()
--    --        OpenJobCenter()
--    --    end
--    --})
--
--    --VFW.CreatePed(vector4(60.200622558594, 129.7130279541, 78.224227905273, 178.23), "s_m_m_cntrybar_01")
--
--    --VFW.CreateBlipAndPoint("gopostal", vector3(60.200622558594, 129.7130279541, 79.224227905273), "gopostal", 541, 2, 0.8, "Go Postal", "Go Postal", "E", "Stockage",{
--    --    onPress = function()
--    --        OpenMenuGoPostal()
--    --    end
--    --})
--
--    --VFW.CreateBlipAndPoint("pizzeria", vector3(287.37, -963.98, 28.42 + 0.75), "pizzeria", 267, 2, 0.8, "Pizzeria", "Pizzeria", "E", "Pizza",{
--    --    onPress = function()
--    --        OpenMenuPizzeriaInt()
--    --    end
--    --})
--    --VFW.CreatePed(vector4(287.37, -963.98, 28.42, 358.7), "s_m_m_cntrybar_01")
--
--    --VFW.CreateBlipAndPoint("tramway", vector3(-534.93597412109, -674.98834228516, 10.808974266052 + 0.75), "tramway", 532, 2, 0.8, "Tramway", "Tramway", "E", "Tramway",{
--    --    onPress = function()
--    --        OpenMenuTramway()
--    --    end
--    --})
--    --VFW.CreatePed(vector4(-534.93597412109, -674.98834228516, 10.808974266052, 272.13305664062), "a_m_y_business_02")
--
--    --VFW.CreateBlipAndPoint("trainint", vector3(-139.5951385498, 6146.96875, 31.436786651611 + 0.75), "trainint", 528, 2, 0.8, "Train", "Train", "E", "Tramway",{
--    --    onPress = function()
--    --        OpenMenuTraiInter()
--    --    end
--    --})
--    --VFW.CreatePed(vector4(2829.0295410156, 2810.6799316406, 56.414730072021, 170.57766723633), "s_m_y_dockwork_01")
--
--    --VFW.CreateBlipAndPoint("mine", vector3(2829.0295410156, 2810.6799316406, 58.414730072021), "mine", 237, 2, 0.8, "Mineur", "Mineur", "E", "Mine",{
--    --    onPress = function()
--    --        OpenMenuMine()
--    --    end
--    --})
--
--    --VFW.CreatePed(vector4(-1492.5665283203, 4977.8598632813, 62.541934967041, 50.697154998779), "s_m_m_linecook")
--
--    --VFW.CreateBlipAndPoint("chasse", vector3(-1492.5665283203, 4977.8598632813, 64.541934967041), "chasse", 463, 2, 0.8, "Chasse", "Chasse", "E", "Mine",{
--    --    onPress = function()
--    --        OpenMenuChasse()
--    --    end
--    --})
--
--    --VFW.CreatePed(vector4(-991.59698486328, -2943.2504882812, 12.957759857178, 67.605926513672), "s_m_m_pilot_01")
--
--    --VFW.CreateBlipAndPoint("CdrAvion", vector3(-991.59698486328, -2943.2504882812, 12.957759857178 + 1.0), "CdrAvion", 423, 2, 0.8, "Conducteur d'Avion", "Conducteur", "E", "Avion",{
--    --    onPress = function()
--    --        OpenMenuCdrAvion()
--    --    end
--    --})
--
--    --VFW.CreatePed(vector4(861.49505615234, -3185.6682128906, 5.0349578857422, 358.85681152344), "s_m_m_cntrybar_01")
--
--    --VFW.CreateBlipAndPoint("routier", vector3(861.49505615234, -3185.6682128906, 5.0349578857422 + 1.0), "routier", 67, 2, 0.8, "Routier", "Routier", "E", "Routier",{
--    --    onPress = function()
--    --        OpenMenuRoutier()
--    --    end
--    --})
--
--    --VFW.CreatePed(vector4(2138.22, 4796.54, 40.12, 29.04), "s_m_y_fireman_01")
--
--    --VFW.CreateBlipAndPoint("canadair", vector3(2138.22, 4796.54, 40.12 + 1.0), "canadair", 16, 2, 0.8, "Canadair", "Canadair", "E", "Avion",{
--    --    onPress = function()
--    --        OpenMenuCanadair()
--    --    end
--    --})
--
--    -- Legal services
--    --for serviceName, serviceConfig in pairs(Config.Features.Sonnette) do
--    --    for _, position in ipairs(serviceConfig.pos) do
--    --        VFW.CreatePed(position, serviceConfig.ped)
--    --        VFW.CreateBlipAndPoint("sonnette", vector3(position.x, position.y, position.z + 1.25), serviceName, nil, nil, nil, nil, "Sonnette", "E", "Sonnette", {
--    --            onPress = function()
--    --                TriggerServerEvent('core:alert:makeCall', serviceName, position, false, serviceConfig.msg, true)
--    --            end
--    --        })
--    --    end
--    --end
--
--    --if VFW.PlayerData.job and VFW.PlayerData.job.name == "usmc" then
--    --    VFW.CreateBlipAndPoint("surveillance", vector3(-2211.68, 3424.5, 34.03), "surveillance", nil, nil, nil, nil, "Surveillance", "E", "Surveillance", {
--    --        onPress = function()
--    --            if VFW.PlayerData.job and VFW.PlayerData.job.name == "usmc" then
--    --                StartOrbital()
--    --            end
--    --        end
--    --    })
--    --end
--
--    --VFW.CreatePed(vector4(-139.5951385498, 6146.96875, 31.436786651611, 218.27481079102), "a_m_y_business_01")
--
--    --VFW.CreateBlipInternal(vector3(-805.83, -1354.64, 4.18), 404, 47, 0.8, "HeliWave")
--    -- Boites de nuit :
--    --VFW.CreateBlipInternal(vector3(-296.41, -106.34, 46.05), 267, 1, 0.8, "Pawnshop")
--    -- 911 :
--    --VFW.CreateBlipInternal(vector3(-1096.03, -837.89, 18.33), 60, 0, 0.8, "LSPD VP")
--    --VFW.CreateBlipInternal(vector3(440.13, -982.43, 29.69), 60, 0, 0.8, "LSPD MR")
--    --VFW.CreateBlipInternal(vector3(1816.87, 3672.44, 33.71), 137, 0, 0.8, "LSSD")
--    --VFW.CreateBlipInternal(vector3(-466.32, 7086.44, 21.38), 137, 0, 0.8, "LSSD")
--    --VFW.CreateBlipInternal(vector3(344.26, -587.68, 27.78), 61, 0, 0.8, "SAMS")
--    --VFW.CreateBlipInternal(vector3(-509.52, 7364.57, 11.84), 61, 0, 0.8, "SAMS")
--    --VFW.CreateBlipInternal(vector3(2542.17, -381.82, 91.99), 419, 0, 0.8, "USSS")
--    --VFW.CreateBlipInternal(vector3(-1039.92, -1400.68, 4.08), 436, 1, 0.8, "LSFD")
--    --VFW.CreateBlipInternal(vector3(-429.58, 7071.68, 20.68), 436, 1, 0.8, "LSFD")
--    --VFW.CreateBlipInternal(vector3(-552.28, -191.53, 37.22), 419, 0, 0.8, "Gouvernement")
--    --VFW.CreateBlipInternal(vector3(232.75, -418.38, 47.1), 419, 0, 0.8, "DOJ")
--    ---- Autres :
--    --VFW.CreateBlipInternal(vector3(-719.4, -1325.9, 0.6), 356, 3, 0.8, "Garage Bateaux")
--end)

local interactionZones = {}
local menuAbierto = false

RegisterNetEvent('vfw_interaction:setMenuState')
AddEventHandler('vfw_interaction:setMenuState', function(state)
    menuAbierto = state
end)

-- 1. Definimos la función de registro GLOBALMENTE (fuera de hilos)
function CreateMarkerAndInteraction(pos, title, blipSprite, blipColor, helpText, action, colorTable,isPed)
    -- Crear el Blip
    VFW.CreateBlipInternal({pos = vector3(pos.x, pos.y, pos.z)}, blipSprite, blipColor, 0.8, title)

    -- Guardar la zona
    table.insert(interactionZones, {
        pos = pos,
        helpText = helpText,
        action = action,
        color = colorTable,
        isPed = isPed or false
    })
end


-- 2. Hilo ÚNICO para procesar la distancia (Siempre activo)
--Citizen.CreateThread(function()
--    while true do
--        local sleep = 1000
--        local playerCoords = GetEntityCoords(PlayerPedId())
--
--        if not cams then
--            for _, zone in ipairs(interactionZones) do
--                local dist = #(playerCoords - vector3(zone.pos.x, zone.pos.y, zone.pos.z))
--
--                if dist < 5.0 then
--                    sleep = 0
--                    local rgb = zone.color or {139, 106, 34} -- Color por defecto si no hay uno definido
--                    DrawMarker(25, zone.pos.x, zone.pos.y, zone.pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, rgb[1], rgb[2], rgb[3], 150, false, false, 2, false, nil, nil, false)
--
--                    if dist < 1.5 then
--                        BeginTextCommandDisplayHelp("STRING")
--                        AddTextComponentSubstringPlayerName(zone.helpText)
--                        EndTextCommandDisplayHelp(0, false, true, -1)
--
--                        if VFW.Interact.JustPressed(1, 38) then
--                            zone.action()
--                        end
--                    end
--                end
--            end
--        end
--        Wait(sleep)
--    end
--end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000

        -- Si el menú NO está abierto, procesamos marcadores
        if not menuAbierto then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for _, zone in ipairs(interactionZones) do
                local dist = #(playerCoords - vector3(zone.pos.x, zone.pos.y, zone.pos.z))

                if dist < 5.0 then
                    sleep = 0

                    if not zone.isPed then
                        local rgb = zone.color or {139, 106, 34}
                        DrawMarker(25, zone.pos.x, zone.pos.y, zone.pos.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, rgb[1], rgb[2], rgb[3], 150, false, false, 2, false, nil, nil, false)
                    end


                    if dist < 1.5 then
                        VFW.ShowHelpNotification(zone.helpText)

                        if VFW.Interact.JustPressed(1, 38) then
                            zone.action()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)



CreateThread(function()
    while not VFW.PlayerLoaded do
        Wait(100)
    end

    -- REGISTRO DE MÁSCARAS
    --for key, value in pairs(Config.Features.Masque) do
    --    local firstCOH = value[1].COH
    --    CreateMarkerAndInteraction(firstCOH, "Magasin de masque", 362, 47, "Appuyez sur ~INPUT_CONTEXT~ pour accéder aux ~y~Masques~s~.", function()
    --        TriggerEvent('skinchanger:getSkin', function(skin)
    --            if skin.sex == 0 or skin.sex == 1 then
    --                --SetEntityCoords(PlayerPedId(), firstCOH.x, firstCOH.y, firstCOH.z - 1.0)
    --                --SetEntityHeading(PlayerPedId(), firstCOH.w)
    --                OpenModernClothingShop({
    --                    Title = "MASK SHOP",
    --                    shopType = "mask"
    --                }, false)
    --            else
    --                VFW.ShowNotification({type = "ROUGE", content = "Les peds ne peuvent pas utiliser le magasin de masque."})
    --            end
    --        end)
    --    end,{128, 0, 128})
    --end

    -- Mask shops are now managed by the builder shop system (cl_shops.lua)
    -- No longer need hardcoded mask shop from Config.Features.Masque
end)
