-- Market Builder Configuration Menu
-- Global delivery time configuration for all jobs

-- Cache for delivery settings + global enabled flag
local cachedSettings = {min = 60, max = 300, enabled = true}



--- Fetch global delivery settings from server (async)
local function getDeliverySettings(callback)
    local settings = TriggerServerCallback('spacemarket:get:delivery_settings')
    if settings then
        cachedSettings = {
            min = settings.min or 60,
            max = settings.max or 300,
            enabled = (settings.enabled ~= false)
        }
    end
    if callback then callback(cachedSettings) end
end

--- Build Market Configuration Menu
function StaffMenu.BuildMarketDeliveryMenu()
    -- Use cached settings (will be updated after first load)
    local minTime = tonumber(cachedSettings.min) or 60
    local maxTime = tonumber(cachedSettings.max) or 300
    local enabled = (cachedSettings.enabled ~= false)

    -- Fetch current locations & ped model from server (sync)
    local locData = TriggerServerCallback('spacemarket:get:locations') or {}
    local locations = locData.locations or {}
    local pedModel = locData.pedModel or "a_m_y_business_02"

  -- Global enable/disable toggle (affects all Markets: PNJ + interactions)
    StaffMenu.builderMarketDelivery.Checkbox(
        ":check: MARKET GLOBAL",
        "Activer ou désactiver tous les Markets (PNJ + interactions)",
        false,
        enabled,
        function(value)
            cachedSettings.enabled = value and true or false
            TriggerServerEvent("spacemarket:set:delivery_settings", minTime, maxTime, cachedSettings.enabled)
        end
    )

    StaffMenu.builderMarketDelivery.Separator("CONFIGURATION DÉLAIS")

    StaffMenu.builderMarketDelivery.Button(
        ":clock: Temps minimum: " .. minTime .. "s",
        "Configurer le temps minimum de livraison",
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Temps minimum de livraison (en secondes)", tostring(minTime))
            if input and input ~= "" then
                local newMin = tonumber(input)
                if not newMin or newMin < 1 then
                    return
                end
                
                if newMin >= maxTime then
                    return
                end
                
                TriggerServerEvent("spacemarket:set:delivery_settings", newMin, maxTime)
                cachedSettings.min = newMin
            end
        end
    )

    StaffMenu.builderMarketDelivery.Button(
        ":clock: Temps maximum: " .. maxTime .. "s",
        "Configurer le temps maximum de livraison",
        nil,
        nil,
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Temps maximum de livraison (en secondes)", tostring(maxTime))
            if input and input ~= "" then
                local newMax = tonumber(input)
                if not newMax or newMax < 1 then
                    return
                end
                
                if newMax <= minTime then
                    return
                end
                
                TriggerServerEvent("spacemarket:set:delivery_settings", minTime, newMax)
                cachedSettings.max = newMax
            end
        end
    )

    StaffMenu.builderMarketDelivery.Button(
        ":chart: Plage globale: " .. minTime .. "s à " .. maxTime .. "s",
        "Aléatoire entre ces deux valeurs pour TOUS les jobs",
        nil,
        nil,
        true,
        function() end
    )

    -- Ped model configuration
    StaffMenu.builderMarketDelivery.Separator("CONFIGURATION PNJ / POSITIONS")
    StaffMenu.builderMarketDelivery.Button(
        ":user: Modèle du PNJ",
        pedModel,
        nil,
        "chevron",
        false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nom du modèle du PNJ (ex: a_m_y_business_02)", pedModel)
            if input and input ~= "" then
                TriggerServerEvent("spacemarket:setPedModel", input)

            end
        end
    )

    -- Liste des Markets avec édition de position
    if locations and #locations > 0 then
        for i, loc in ipairs(locations) do
            local name = loc.name or ("Space Market " .. tostring(i))

            StaffMenu.builderMarketDelivery.Button(
                (":pin: %s - Position PNJ"):format(name),
                "Placer le PNJ Market à la position actuelle du joueur",
                nil,
                nil,
                false,
                function()
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    TriggerServerEvent("spacemarket:updateLocation", i, {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        w = heading
                    }, nil)

                end
            )

            StaffMenu.builderMarketDelivery.Button(
                (":box: %s - Position drop"):format(name),
                "Placer le point de livraison (coffre) à la position actuelle du joueur",
                nil,
                nil,
                false,
                function()
                    local ped = PlayerPedId()
                    local coords = GetEntityCoords(ped)
                    local heading = GetEntityHeading(ped)
                    TriggerServerEvent("spacemarket:updateLocation", i, nil, {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z -1.0, 
                        w = heading
                    })

                end
            )
        end
    else
        StaffMenu.builderMarketDelivery.Button("Aucune position Market configurée", nil, nil, nil, true, function() end)
    end
end

--- Build Market Job Delivery Configuration Submenu (unused)
function StaffMenu.BuildMarketDeliveryConfigMenu()
    -- Cette fonction n'est plus utilisée
end

-- Initialiser les settings au démarrage
getDeliverySettings()
