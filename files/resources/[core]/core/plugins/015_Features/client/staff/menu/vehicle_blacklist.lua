---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- Vehicle Blacklist Menu (Dev)
-- ============================================================

function StaffMenu.BuildVehicleBlacklistMenu()
    StaffMenu.vehBlacklist.ClearItems()

    StaffMenu.vehBlacklist.Button(":plus: Ajouter un modèle", "Bloque le spawn de ce modèle pour tout le monde", nil, "chevron", false, function()
        local model = VFW.Nui.KeyboardInput(true, "Spawn name du véhicule (ex: oppressor2)")
        if not model or model == "" then return end

        local reason = VFW.Nui.KeyboardInput(true, "Raison (optionnel)", "")

        local result = TriggerServerCallback("vfw:staff:vehBlacklist:add", model, reason)
        if result and result.success then
            VFW.ShowNotification({
                type = 'STAFF', variant = 'SUCCESS',
                subtitle = 'Vehicle Blacklist', message = result.message
            })
        else
            VFW.ShowNotification({
                type = 'ROUGE',
                content = result and result.message or "Erreur"
          })
        end
        StaffMenu.vehBlacklist.refresh()
    end)

    StaffMenu.vehBlacklist.Separator("MODÈLES BLACKLIST")

    local items = TriggerServerCallback("vfw:staff:vehBlacklist:list") or {}

    if #items == 0 then
        StaffMenu.vehBlacklist.Button("Aucun modèle blacklist", nil, nil, nil, true, function() end)
        return
    end

    for _, entry in ipairs(items) do
        local subtitle
        if entry.reason and entry.reason ~= "" then
            subtitle = "Raison: " .. entry.reason
        else
            subtitle = "Cliquer pour retirer"
      end
        if entry.added_by and entry.added_by ~= "" then
            subtitle = subtitle .. ", par " .. entry.added_by
        end

        StaffMenu.vehBlacklist.Button(":ban: " .. entry.model, subtitle, nil, "trash", false, function()
            local result = TriggerServerCallback("vfw:staff:vehBlacklist:remove", entry.model)
            if result and result.success then
                VFW.ShowNotification({
                    type = 'STAFF', variant = 'SUCCESS',
                    subtitle = 'Vehicle Blacklist', message = result.message
                })
            else
                VFW.ShowNotification({
                    type = 'ROUGE',
                    content = result and result.message or "Erreur"
              })
            end
            StaffMenu.vehBlacklist.refresh()
        end)
    end
end
