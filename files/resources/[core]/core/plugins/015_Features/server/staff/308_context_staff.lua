---@meta _
---@diagnostic disable: duplicate-doc-field

-- Actions Alt (menu contextuel) : heal / faim / soif / armure / kill sur soi

local function registerStaffSelfActions()
    if type(VFW.ContextMenu) ~= "table" then return false end
    if type(VFW.ContextMenu.RegisterAction) ~= "function" then return false end

    local register = VFW.ContextMenu.RegisterAction

    register("staff:heal", function(source, _, _, _, xPlayer)
        if not xPlayer then return { ok = false, err = "Joueur introuvable." } end
        xPlayer.setMeta("health", 200)
        TriggerClientEvent("vfw:healPlayer", source)
        return { ok = true, msg = "Santé restaurée" }
    end, "alt_heal")

    register("staff:eat", function(source)
        VFW.SetStatus(source, 100, nil)
        return { ok = true, msg = "Faim remplie" }
    end, "alt_heal")

    register("staff:thirst", function(source)
        VFW.SetStatus(source, nil, 100)
        return { ok = true, msg = "Soif remplie" }
    end, "alt_heal")

    register("staff:armor", function(source)
        local ped = GetPlayerPed(source)
        if ped and ped ~= 0 then
            SetPedArmour(ped, 100)
        end
        TriggerClientEvent("vfw:setArmor", source, 100)
        return { ok = true, msg = "Armure appliquée" }
    end, "alt_heal")

    register("staff:kill", function(source)
        TriggerClientEvent("vfw:killPlayer", source, source)
        return { ok = true, msg = "Vous vous êtes tué." }
    end, "alt_heal")

    return true
end

CreateThread(function()
    for _ = 1, 100 do
        if registerStaffSelfActions() then return end
        Wait(100)
    end
end)
