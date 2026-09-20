local interimData = nil
local selectedJob = nil

local tierLabels = {
    [1] = "Bronze",
    [2] = "Silver",
    [3] = "Gold"
}

local function fetchEconomyData()
    local result = TriggerServerCallback("interim:admin:getEconomyConfig")
    if result and result.success then
        interimData = result
    end
    return result
end

StaffMenu.builderInterim.OnOpen(function()
    StaffMenu.builderInterim.ClearItems()

    fetchEconomyData()

    if not interimData or not interimData.jobs then
        StaffMenu.builderInterim.Button("Erreur", "Impossible de charger les données", nil, nil, true, function() end)
        return
    end

    StaffMenu.builderInterim.Separator("ÉCONOMIE INTÉRIM")

    for _, job in ipairs(interimData.jobs) do
        local itemCount = #job.items
        local desc = itemCount .. " prix configurable" .. (itemCount > 1 and "s" or "")

        StaffMenu.builderInterim.Button(
            job.label,
            desc,
            nil,
            "chevron",
            false,
            function()
                selectedJob = job
            end,
            StaffMenu.builderInterimJob
        )
    end
end)

StaffMenu.builderInterimJob.OnOpen(function()
    StaffMenu.builderInterimJob.ClearItems()

    if not selectedJob or not interimData then
        StaffMenu.builderInterimJob.Button("Erreur", "Aucun job sélectionné", nil, nil, true, function() end)
        return
    end

    fetchEconomyData()
    if interimData and interimData.jobs then
        for _, job in ipairs(interimData.jobs) do
            if job.id == selectedJob.id then
                selectedJob = job
                break
            end
        end
    end

    local mults = interimData.vipMultipliers or {}

    StaffMenu.builderInterimJob.Separator(string.upper(selectedJob.label))

    for _, item in ipairs(selectedJob.items) do
        local basePrice = item.value

        local vipDesc = ""
      for tier = 1, 3 do
            local mult = mults[tier] or 1
            if mult > 1 then
                local vipGain = math.floor(basePrice * mult)
                vipDesc = vipDesc .. tierLabels[tier] .. ": " .. VFW.Math.FormatMoney(vipGain) .. " "
          end
        end

        local desc = "Base: " .. VFW.Math.FormatMoney(basePrice)
      if vipDesc ~= "" then
            desc = desc .. " | " .. vipDesc
        end

        StaffMenu.builderInterimJob.Button(
            item.label,
            desc,
            nil,
            "edit",
            false,
            function()
                local input = VFW.Nui.KeyboardInput(true, item.label .. " (actuel: " .. VFW.Math.FormatMoney(basePrice) .. ")")
                if not input or input == "" then return end

                local newVal = tonumber(input)
                if not newVal or newVal < 0 then
                    VFW.ShowNotification({ type = "ROUGE", content = "Cette valeur n'est pas valide : entrez un nombre positif" })
                    return
                end

                local res = TriggerServerCallback("interim:admin:setPrice", {
                    jobId = selectedJob.id,
                    key = item.key,
                    value = newVal
                })

                if res and res.success then
                    VFW.ShowNotification({ type = "VERT", content = item.label .. " mis à jour: " .. VFW.Math.FormatMoney(newVal) })
                    StaffMenu.builderInterimJob.refresh()
                else
                    VFW.ShowNotification({ type = "ROUGE", content = res and res.message or "Erreur" })
                end
            end
        )
    end
end)
