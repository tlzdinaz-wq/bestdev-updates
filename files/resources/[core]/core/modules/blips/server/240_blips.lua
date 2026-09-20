local blipsList = {}
local loaded = false

VFW.Blips = VFW.Blips or {}

local function toBlipData(row)
    return {
        position = { x = row.x + 0.0, y = row.y + 0.0, z = row.z + 0.0 },
        label = row.label,
        sprite = row.sprite or 1,
        color = row.color or 0,
        scale = (row.scale or 0.5) + 0.0,
    }
end

local function sanitize(data)
    if type(data) ~= "table" then return nil end

    local position = data.position or data.positions or data.coords
    if type(position) ~= "table" then return nil end

    local x, y, z = tonumber(position.x), tonumber(position.y), tonumber(position.z)
    if not x or not y or not z then return nil end

    local label = data.label or data.nom or data.name
    if type(label) ~= "string" or label == "" then return nil end

    local sprite = math.floor(tonumber(data.sprite) or 1)
    local color = math.floor(tonumber(data.color or data.couleur) or 0)
    local scale = tonumber(data.scale or data.taille) or 0.5

    if sprite < 0 then sprite = 1 end
    if color < 0 then color = 0 end
    if scale <= 0.0 then scale = 0.5 end
    if scale > 3.0 then scale = 3.0 end

    return {
        position = { x = x, y = y, z = z },
        label = label:sub(1, 64),
        sprite = sprite,
        color = color,
        scale = scale + 0.0,
    }
end

function VFW.Blips.GetAll()
    return blipsList
end

function VFW.Blips.Get(blipId)
    return blipsList[tostring(blipId)]
end

function VFW.Blips.SyncTo(source)
    source = tonumber(source)
    if not source or source <= 0 then return end
    TriggerClientEvent("blips:retrieve:list", source, blipsList)
end

function VFW.Blips.SyncAll()
    TriggerClientEvent("blips:retrieve:list", -1, blipsList)
end

function VFW.Blips.Create(data, createdBy)
    local blipData = sanitize(data)
    if not blipData then return nil end

    local insertId = MySQL.insert.await(
        "INSERT INTO `blips` (`label`, `sprite`, `color`, `scale`, `x`, `y`, `z`, `created_by`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        {
            blipData.label,
            blipData.sprite,
            blipData.color,
            blipData.scale,
            blipData.position.x,
            blipData.position.y,
            blipData.position.z,
            type(createdBy) == "string" and createdBy:sub(1, 80) or "",
        }
    )

    if not insertId then return nil end

    local key = tostring(insertId)
    blipsList[key] = blipData

    TriggerClientEvent("blips:add:list", -1, key, blipData)
    TriggerEvent("vfw:blips:created", key, blipData)

    return key
end

function VFW.Blips.Update(blipId, data)
    local key = tostring(blipId)
    local current = blipsList[key]
    if not current then return false end

    local merged = {
        position = current.position,
        label = current.label,
        sprite = current.sprite,
        color = current.color,
        scale = current.scale,
    }

    if type(data) == "table" then
        local incoming = sanitize({
            position = data.position or data.positions or data.coords or current.position,
            label = data.label or data.nom or data.name or current.label,
            sprite = data.sprite or current.sprite,
            color = data.color or data.couleur or current.color,
            scale = data.scale or data.taille or current.scale,
        })
        if not incoming then return false end
        merged = incoming
    end

    MySQL.update.await(
        "UPDATE `blips` SET `label` = ?, `sprite` = ?, `color` = ?, `scale` = ?, `x` = ?, `y` = ?, `z` = ? WHERE `id` = ?",
        {
            merged.label,
            merged.sprite,
            merged.color,
            merged.scale,
            merged.position.x,
            merged.position.y,
            merged.position.z,
            tonumber(blipId),
        }
    )

    blipsList[key] = merged

    TriggerClientEvent("blips:update:list", -1, key, merged)
    TriggerEvent("vfw:blips:updated", key, merged)

    return true
end

function VFW.Blips.Remove(blipId)
    local key = tostring(blipId)
    if not blipsList[key] then return false end

    MySQL.update.await("DELETE FROM `blips` WHERE `id` = ?", { tonumber(blipId) })

    blipsList[key] = nil

    TriggerClientEvent("blips:remove:list", -1, key)
    TriggerEvent("vfw:blips:removed", key)

    return true
end

local function load()
    local rows = MySQL.query.await("SELECT * FROM `blips`") or {}

    blipsList = {}
    for i = 1, #rows do
        blipsList[tostring(rows[i].id)] = toBlipData(rows[i])
    end

    loaded = true
    console.init("Blips", ("%d blips serveur charges"):format(#rows))
end

AddEventHandler("vfw:characterLoaded", function(source)
    if not loaded then return end
    VFW.Blips.SyncTo(source)
end)

AddEventHandler("vfw:playerLoaded", function(source)
    if not loaded then return end
    VFW.Blips.SyncTo(source)
end)

AddEventHandler("vfw:blips:register", function(data, createdBy)
    VFW.Blips.Create(data, createdBy)
end)

MySQL.ready(function()
    local ok, err = pcall(load)
    if not ok then
        console.error(("[Blips] chargement impossible : %s"):format(tostring(err)))
        loaded = true
    end
end)

CreateThread(function()
    local tries = 0
    while not VFW.RegisterCommand and tries < 200 do
        Wait(250)
        tries = tries + 1
    end
    if not VFW.RegisterCommand then return end

    Wait(1000)

    local existing = VFW.GetRegisteredCommands and VFW.GetRegisteredCommands() or {}

    if not existing["blipadd"] then
        VFW.RegisterCommand("blipadd", "manage_blips", function(source, xPlayer, args)
            if not xPlayer then return end

            local label = table.concat(args, " ", 4)
            local coords = xPlayer.getCoords(false)

            local key = VFW.Blips.Create({
                position = coords,
                label = label,
                sprite = tonumber(args[1]),
                color = tonumber(args[2]),
                scale = tonumber(args[3]),
            }, xPlayer.identifier)

            xPlayer.showNotification({
                type = "STAFF",
                variant = key and "SUCCESS" or "ERROR",
                subtitle = "Blips",
                message = key and ("Blip #%s cree."):format(key) or "Usage : /blipadd <sprite> <couleur> <taille> <nom>",
            })
        end, {
            help = "Cree un blip serveur persistant a votre position.",
            params = {
                { name = "sprite", help = "Identifiant du sprite" },
                { name = "couleur", help = "Identifiant de couleur" },
                { name = "taille", help = "Echelle (0.1 - 3.0)" },
                { name = "nom", help = "Nom affiche" },
            },
        })
    end

    if not existing["blipdel"] then
        VFW.RegisterCommand("blipdel", "manage_blips", function(source, xPlayer, args)
            if not xPlayer then return end

            local blipId = tonumber(args[1])
            local removed = blipId and VFW.Blips.Remove(blipId) or false

            xPlayer.showNotification({
                type = "STAFF",
                variant = removed and "SUCCESS" or "ERROR",
                subtitle = "Blips",
                message = removed and ("Blip #%d supprime."):format(blipId) or "Blip introuvable.",
            })
        end, {
            help = "Supprime un blip serveur persistant.",
            params = { { name = "id", help = "Identifiant du blip" } },
        })
    end

    if not existing["bliplist"] then
        VFW.RegisterCommand("bliplist", "manage_blips", function(source, xPlayer)
            local count = 0
            for key, blip in pairs(blipsList) do
                count = count + 1
                console.info(("[Blips] #%s %s sprite=%d couleur=%d taille=%.2f (%.2f, %.2f, %.2f)"):format(
                    key, blip.label, blip.sprite, blip.color, blip.scale,
                    blip.position.x, blip.position.y, blip.position.z))
            end

            if xPlayer then
                xPlayer.showNotification({
                    type = "STAFF",
                    variant = "INFO",
                    subtitle = "Blips",
                    message = ("%d blips serveur (details en console)."):format(count),
                })
            end
        end, { help = "Liste les blips serveur persistants.", allowConsole = true })
    end
end)
