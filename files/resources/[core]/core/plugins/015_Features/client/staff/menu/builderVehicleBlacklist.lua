-- ============================================================
-- Staff Menu: Vehicle Blacklist Builder
-- Liste des véhicules blacklistés (ajout / suppression)
-- ============================================================

function StaffMenu.BuildVehicleBlacklistMenu()
    if not StaffMenu or not StaffMenu.vehBlacklist then return end

    local list = TriggerServerCallback("vfw:staff:vehBlacklist:list") or {}

    StaffMenu.vehBlacklist.Separator(string.format("VÉHICULES BLACKLISTÉS (%d)", #list))

    StaffMenu.vehBlacklist.Button(":plus: AJOUTER UN VÉHICULE", "Bloquer le spawn d'un modèle", nil, "arrow", false, function()
        local model = VFW.Nui.KeyboardInput(true, "Nom du modèle (ex: adder, t20)")
        if not model or model == "" then return end

        local reason = VFW.Nui.KeyboardInput(true, "Raison (optionnel)")

        local result = TriggerServerCallback("vfw:staff:vehBlacklist:add", model, reason or "")
        if result and result.success then
            VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Blacklist véhicule", message = result.message })
            StaffMenu.vehBlacklist.refresh()
        else
            VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Blacklist véhicule", message = result and result.message or "Erreur" })
        end
    end)

    if #list == 0 then
        StaffMenu.vehBlacklist.Separator("Aucun véhicule blacklisté")
        return
    end

    StaffMenu.vehBlacklist.Separator("LISTE")

    for _, entry in ipairs(list) do
        local model = entry.model or "?"
      local reason = entry.reason and entry.reason ~= "" and entry.reason or "Sans raison"

      StaffMenu.vehBlacklist.Button(model, reason, "RETIRER", nil, false, function()
            local result = TriggerServerCallback("vfw:staff:vehBlacklist:remove", model)
            if result and result.success then
                VFW.ShowNotification({ type = "STAFF", variant = "SUCCESS", subtitle = "Blacklist véhicule", message = result.message })
                StaffMenu.vehBlacklist.refresh()
            else
                VFW.ShowNotification({ type = "STAFF", variant = "ERROR", subtitle = "Blacklist véhicule", message = result and result.message or "Erreur" })
            end
        end)
    end
end
