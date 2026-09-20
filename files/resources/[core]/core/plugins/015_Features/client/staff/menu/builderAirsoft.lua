local selectedAirsoftWeapon = nil

local airsoftWeaponList = {}
for _, w in ipairs(Config.Weapons) do
    if w.airsoft then
        table.insert(airsoftWeaponList, { name = w.name:upper(), label = w.label })
    end
end
table.sort(airsoftWeaponList, function(a, b) return a.label < b.label end)

local function BuildAirsoftDetailMenu()
    if not selectedAirsoftWeapon or not StaffMenu.builderAirsoftDetail then return end

    local w = selectedAirsoftWeapon
    local gsConfig = GlobalState.AirsoftConfig or {}
    local config = gsConfig[w.name]
    local currentHits = config and config.hitsToDown or AirsoftConfig.defaultHitsToDown
    local currentWindow = config and config.hitWindow or AirsoftConfig.defaultHitWindow
    local Button = StaffMenu.builderAirsoftDetail.Button
    local Separator = StaffMenu.builderAirsoftDetail.Separator

    Separator(w.label)

    Button(
        "Billes pour tomber",
        currentHits .. (currentHits > 1 and " billes" or " bille") .. (not config and " (défaut)" or ""),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Nombre de billes (1-30)")
            if not input then return end
            local val = tonumber(input)
            if not val or val < 1 or val > 30 then
                VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide (1-30)" })
                return
            end
            local success = TriggerServerCallback("vfw:airsoft:update", w.name, "hitsToDown", math.floor(val))
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Airsoft', message = w.label .. " : " .. math.floor(val) .. (val > 1 and " billes pour tomber" or " bille pour tomber") })
                Wait(200)
                StaffMenu.builderAirsoftDetail.refresh()
            end
        end
    )

    Button(
        "Fenêtre de temps",
        (currentWindow / 1000) .. ((currentWindow / 1000) > 1 and " secondes" or " seconde") .. (not config and " (défaut)" or ""),
        nil, nil, false,
        function()
            local input = VFW.Nui.KeyboardInput(true, "Durée en secondes (1-30)")
            if not input then return end
            local val = tonumber(input)
            if not val or val < 1 or val > 30 then
                VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide (1-30)" })
                return
            end
            local ms = math.floor(val) * 1000
            local success = TriggerServerCallback("vfw:airsoft:update", w.name, "hitWindow", ms)
            if success then
                VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Airsoft', message = w.label .. " : fenêtre de " .. math.floor(val) .. "s" })
                Wait(200)
                StaffMenu.builderAirsoftDetail.refresh()
            end
        end
    )

    Separator("ACTIONS")

    Button("Réinitialiser", "Revenir aux valeurs par défaut", nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:airsoft:reset", w.name)
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Airsoft', message = w.label .. " réinitialisé" })
            Wait(200)
            StaffMenu.builderAirsoftDetail.refresh()
        end
    end)
end

local function BuildAirsoftMenu()
    if not StaffMenu or not StaffMenu.builderAirsoft then return end

    local gsConfig = GlobalState.AirsoftConfig or {}
    local Button = StaffMenu.builderAirsoft.Button
    local Separator = StaffMenu.builderAirsoft.Separator

    local totalConfigured = 0
    for _ in pairs(gsConfig) do totalConfigured = totalConfigured + 1 end

    Separator("ACTIONS RAPIDES")

    Button("Tout réinitialiser", totalConfigured .. (totalConfigured > 1 and " armes configurées" or " arme configurée"), nil, "trash", false, function()
        local success = TriggerServerCallback("vfw:airsoft:resetAll")
        if success then
            VFW.ShowNotification({ type = 'STAFF', variant = 'SUCCESS', subtitle = 'Airsoft', message = "Toutes les configurations supprimées" })
            Wait(200)
            StaffMenu.builderAirsoft.refresh()
        end
    end)

    Separator("ARMES AIRSOFT")

    for _, w in ipairs(airsoftWeaponList) do
        local config = gsConfig[w.name]
        local hasConf = config ~= nil
        local icon = hasConf and "check" or "empty"
      local desc
        if hasConf then
            desc = config.hitsToDown .. (config.hitsToDown > 1 and " billes en " or " bille en ") .. (config.hitWindow / 1000) .. "s"
      else
            desc = "Défaut (" .. AirsoftConfig.defaultHitsToDown .. " billes / " .. (AirsoftConfig.defaultHitWindow / 1000) .. "s)"
      end
        Button(w.label, desc, nil, icon, false, function()
            selectedAirsoftWeapon = w
        end, StaffMenu.builderAirsoftDetail)
    end
end

if StaffMenu.builderAirsoft and StaffMenu.builderAirsoft.OnOpen then
    StaffMenu.builderAirsoft.OnOpen(function()
        StaffMenu.builderAirsoft.ClearItems()
        BuildAirsoftMenu()
    end)
end

if StaffMenu.builderAirsoftDetail and StaffMenu.builderAirsoftDetail.OnOpen then
    StaffMenu.builderAirsoftDetail.OnOpen(function()
        StaffMenu.builderAirsoftDetail.ClearItems()
        BuildAirsoftDetailMenu()
    end)
end
