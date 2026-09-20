local LICENSE_LABELS = {
    ["dmvschool"] = "Code de la route",
    ["driver"] = "Permis de conduire",
    ["moto"] = "Permis moto",
    ["camion"] = "Permis poids lourd",
    ["avion"] = "Licence de pilote",
    ["helicoptere"] = "Licence helicoptere",
    ["bateau"] = "Permis bateau",
    ["ppa_leger"] = "PPA Categorie Legere",
    ["ppa_lourd"] = "PPA Categorie Lourde",
    ["ppa_leger_temp"] = "PPA Legere (temporaire)",
    ["ppa_lourd_temp"] = "PPA Lourde (temporaire)",
}

local DVM_TYPES = {
    ["driver"] = "car",
    ["moto"] = "motorcycle",
    ["camion"] = "truck",
}

local DMV_GRANTABLE = {
    ["dmvschool"] = true,
    ["driver"] = true,
    ["moto"] = true,
    ["camion"] = true,
    ["avion"] = true,
    ["helicoptere"] = true,
    ["bateau"] = true,
}

local function insertDvm(xPlayer, licenseName)
    local dvmType = DVM_TYPES[licenseName]
    if not dvmType then return end

    Misc30.Update([[
        INSERT INTO `dvm_licenses` (`identifier`, `char_id`, `license_type`, `obtained_at`)
        VALUES (?, ?, ?, NOW())
        ON DUPLICATE KEY UPDATE `char_id` = VALUES(`char_id`)
    ]], { xPlayer.identifier, xPlayer.charId, dvmType })
end

function Misc30.GrantLicense(xPlayer, licenseName)
    if not xPlayer then return false end
    if type(licenseName) ~= "string" or not LICENSE_LABELS[licenseName] then return false end

    local added = xPlayer.addLicense(licenseName, LICENSE_LABELS[licenseName])
    insertDvm(xPlayer, licenseName)

    Misc30.Update([[
        INSERT INTO `user_licenses` (`charid`, `type`, `obtained_date`)
        VALUES (?, ?, NOW())
        ON DUPLICATE KEY UPDATE `obtained_date` = `obtained_date`
    ]], { xPlayer.charId, licenseName })

    xPlayer.triggerEvent("vfw:license:load")

    return added
end

function Misc30.RevokeLicense(xPlayer, licenseName)
    if not xPlayer then return false end
    if type(licenseName) ~= "string" then return false end

    xPlayer.removeLicense(licenseName)

    Misc30.Update("DELETE FROM `user_licenses` WHERE `charid` = ? AND `type` = ?",
        { xPlayer.charId, licenseName })

    local dvmType = DVM_TYPES[licenseName]
    if dvmType then
        Misc30.Update("DELETE FROM `dvm_licenses` WHERE `identifier` = ? AND `license_type` = ?",
            { xPlayer.identifier, dvmType })
    end

    xPlayer.triggerEvent("vfw:license:load")

    return true
end

RegisterNetEvent("vfw:license:addLicense", function(_serverId, licenseName)
    local source = source

    if type(licenseName) ~= "string" or not DMV_GRANTABLE[licenseName] then return end

    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Misc30.RateLimit(source, "addLicense", 2000) then return end

    if Misc30.GrantLicense(xPlayer, licenseName) then
        Misc30.Notify(source, "VERT", ("Permis obtenu : %s"):format(LICENSE_LABELS[licenseName]))
    end
end)

Misc30.Cb("vfw:license:checkLicense", function(source, _serverId, licenseName)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if type(licenseName) ~= "string" then return false end
    return xPlayer.getLicense(licenseName) ~= nil
end)

Misc30.Cb("vfw:license:checkAllLicense", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local out = {}
    if type(xPlayer.licenses) == "table" then
        for i = 1, #xPlayer.licenses do
            local entry = xPlayer.licenses[i]
            if type(entry) == "table" and type(entry.type) == "string" then
                out[entry.type] = true
            end
        end
    end

    return out
end)

Misc30.Cb("dvm:getPlayerLicensesForDocument", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local rows = Misc30.Query([[
        SELECT `license_type`, DATE_FORMAT(`obtained_at`, '%d/%m/%Y') AS `obtained_date_formatted`
        FROM `dvm_licenses`
        WHERE `identifier` = ?
        ORDER BY `obtained_at` ASC
    ]], { xPlayer.identifier })

    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            license_type = rows[i].license_type,
            obtained_date_formatted = rows[i].obtained_date_formatted or "01/01/2024",
        }
    end

    return out
end)

VFW.RegisterCommand("givelicense", "gestion", function(source, xPlayer, args)
    local targetId = Misc30.ToInt(args[1], 1)
    local licenseName = args[2]

    if not targetId or type(licenseName) ~= "string" or not LICENSE_LABELS[licenseName] then
        Misc30.Notify(source, "ROUGE", "Usage : /givelicense [id] [permis]")
        return
    end

    local xTarget = VFW.GetPlayerFromId(targetId)
    if not xTarget then
        Misc30.Notify(source, "ROUGE", "Joueur introuvable.")
        return
    end

    Misc30.GrantLicense(xTarget, licenseName)
    Misc30.Notify(source, "VERT", ("Permis %s donne."):format(licenseName))
end, {
    help = "Donner un permis a un joueur",
    params = {
        { name = "id", help = "ID du joueur" },
        { name = "permis", help = "dmvschool, driver, moto, camion, avion, helicoptere, bateau" },
    },
    allowConsole = true,
})

VFW.RegisterCommand("removelicense", "gestion", function(source, xPlayer, args)
    local targetId = Misc30.ToInt(args[1], 1)
    local licenseName = args[2]

    if not targetId or type(licenseName) ~= "string" then
        Misc30.Notify(source, "ROUGE", "Usage : /removelicense [id] [permis]")
        return
    end

    local xTarget = VFW.GetPlayerFromId(targetId)
    if not xTarget then
        Misc30.Notify(source, "ROUGE", "Joueur introuvable.")
        return
    end

    Misc30.RevokeLicense(xTarget, licenseName)
    Misc30.Notify(source, "VERT", ("Permis %s retire."):format(licenseName))
end, {
    help = "Retirer un permis a un joueur",
    params = {
        { name = "id", help = "ID du joueur" },
        { name = "permis", help = "Nom interne du permis" },
    },
    allowConsole = true,
})

AddEventHandler("vfw:playerLoaded", function(source, xPlayer)
    if not xPlayer then return end
    SetTimeout(8000, function()
        if VFW.GetPlayerFromId(source) then
            TriggerClientEvent("vfw:license:load", source)
        end
    end)
end)
