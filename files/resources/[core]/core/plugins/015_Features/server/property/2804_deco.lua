local PS = VFW.PropertyServer

local MAX_DECO_OBJECTS = 250
local BASE_DECO_SLOTS = 2

local function vipTier(xPlayer)
    if not xPlayer then return 0 end
    if xPlayer.hasPermission("vip_gold") then return 3 end
    if xPlayer.hasPermission("vip_silver") then return 2 end
    if xPlayer.hasPermission("vip_bronze") then return 1 end
    return PS.ToInt(xPlayer.vipTier) or 0
end

local function decoSlots(xPlayer)
    local tier = vipTier(xPlayer)
    local slots = BASE_DECO_SLOTS
    if tier >= 1 then slots = slots + 1 end
    if tier >= 2 then slots = slots + 1 end
    return slots
end

local function sanitizeDeco(deco)
    if type(deco) ~= "table" then return nil end
    local out = {}
    for i = 1, #deco do
        local entry = deco[i]
        if type(entry) == "table" and type(entry.model) == "string" then
            local pos = PS.ReadVec3(entry.pos)
            local rot = PS.ReadVec3(entry.rot)
            if pos and rot then
                out[#out + 1] = {
                    model = entry.model:sub(1, 64),
                    pos = pos,
                    rot = rot,
                }
            end
        end
        if #out >= MAX_DECO_OBJECTS then break end
    end
    return out
end

local function saveList(identifier)
    local rows = MySQL.query.await("SELECT id, name, type, created_at FROM property_deco_saves WHERE identifier = ? ORDER BY id", { identifier }) or {}
    local out = {}
    for i = 1, #rows do
        out[#out + 1] = {
            id = rows[i].id,
            name = rows[i].name,
            type = rows[i].type,
            date = PS.FormatDate(rows[i].created_at),
        }
    end
    return out
end

function PS.ApplyDeco(row, deco, exceptSource)
    row.deco = deco
    MySQL.update("UPDATE properties SET deco = ? WHERE id = ?", { PS.Encode(deco), row.id })
    PS.BroadcastToProperty(row.id, exceptSource, "vfw:property:updateDeco", deco)
end

RegisterServerCallback("vfw:property:getSave", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end
    return saveList(xPlayer.identifier)
end)

RegisterServerCallback("vfw:property:createSave", function(source, name, propertyId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local row = PS.GetProperty(propertyId)
    if not row then return saveList(xPlayer.identifier) end
    if not PS.CanManageCached(source, row.id) then return saveList(xPlayer.identifier) end

    local saveName = PS.SafeString(name, 64) or "Sauvegarde"
    local existing = saveList(xPlayer.identifier)

    if #existing >= decoSlots(xPlayer) then
        xPlayer.showNotification({ type = "ROUGE", content = "Vous n'avez plus de slot de sauvegarde disponible." })
        return existing
    end

    MySQL.insert.await("INSERT INTO property_deco_saves (identifier, name, type, deco, created_at) VALUES (?, ?, ?, ?, ?)", {
        xPlayer.identifier,
        saveName,
        row.property_name,
        PS.Encode(row.deco or {}),
        PS.Now(),
    })

    return saveList(xPlayer.identifier)
end)

RegisterServerCallback("vfw:property:deleteSave", function(source, saveId)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return {} end

    local sid = PS.ToInt(saveId)
    if sid then
        MySQL.update.await("DELETE FROM property_deco_saves WHERE id = ? AND identifier = ?", { sid, xPlayer.identifier })
    end

    return saveList(xPlayer.identifier)
end)

RegisterNetEvent("vfw:property:saveDeco", function(propertyId, deco)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local clean = sanitizeDeco(deco)
    if not clean then return end

    PS.ApplyDeco(row, clean, source)
    PS.Log(row.id, "edit", xPlayer, ("deco %d objet(s)"):format(#clean))
end)

RegisterNetEvent("vfw:property:applySave", function(propertyId, saveId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local row = PS.GetProperty(propertyId)
    if not row then return end
    if not PS.CanManage(source, row.id) then return end

    local sid = PS.ToInt(saveId)
    if not sid then return end

    local save = MySQL.single.await("SELECT * FROM property_deco_saves WHERE id = ? AND identifier = ?", { sid, xPlayer.identifier })
    if not save then
        xPlayer.showNotification({ type = "ROUGE", content = "Sauvegarde introuvable." })
        return
    end

    if save.type ~= row.property_name then
        xPlayer.showNotification({ type = "ROUGE", content = "Cette sauvegarde ne correspond pas a ce type de propriete." })
        return
    end

    local clean = sanitizeDeco(PS.Decode(save.deco, {})) or {}
    PS.ApplyDeco(row, clean, nil)
    TriggerClientEvent("vfw:property:updateDeco", source, clean)
    PS.Log(row.id, "edit", xPlayer, ("deco restauree #%d"):format(sid))
end)
