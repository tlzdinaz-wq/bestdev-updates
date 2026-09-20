Feat27 = Feat27 or {}

local OUTPUT_FOLDER = "paidshop_vehicle_shots"
local DEBUG_PERMISSION = "boutique"

local jobs = {}

local function isAllowed(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    if xPlayer.hasPermission(DEBUG_PERMISSION) then return true end
    if xPlayer.hasPermission("gestion") then return true end
    return false
end

local function sanitizeName(name)
    local clean = tostring(name or "vehicle"):lower():gsub("[^%w_%-]", "_")
    if clean == "" then clean = "vehicle" end
    return clean:sub(1, 48)
end

local function decodeDataUri(data)
    if type(data) ~= "string" then return nil end
    local payload = data:match("^data:image/[%w%+%-%.]+;base64,(.+)$")
    if payload then return payload end
    if data:match("^[%w%+/=%s]+$") then return data end
    return nil
end

RegisterServerCallback("paidshop:debug:getVehicleScreenshotList", function(source)
    if not isAllowed(source) then
        return { success = false, error = "Non autorisé", vehicles = {}, outputFolder = OUTPUT_FOLDER }
    end

    local items = PaidShop.LoadItems()
    local list = items and items.vehicules or {}

    local vehicles = {}
    for i = 1, #list do
        if type(list[i].spawnName) == "string" then
            vehicles[#vehicles + 1] = { spawnName = list[i].spawnName }
        end
    end

    return {
        success = true,
        vehicles = vehicles,
        outputFolder = OUTPUT_FOLDER,
    }
end)

RegisterNetEvent("paidshop:debug:saveVehicleScreenshot", function(spawnName, index, data)
    local source = source
    local slot = tonumber(index)

    if not isAllowed(source) then
        TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
            index = slot or 0, success = false, error = "Non autorisé",
        })
        return
    end

    if type(spawnName) ~= "string" or not slot then
        TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
            index = slot or 0, success = false, error = "Cette demande n'a pas pu être traitée",
        })
        return
    end

    local payload = decodeDataUri(data)
    if not payload then
        TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
            index = slot, success = false, error = "Cette image n'est pas valide",
        })
        return
    end

    local fileName = ("%s/%s.jpg"):format(OUTPUT_FOLDER, sanitizeName(spawnName))
    local binary = nil

    local ok = pcall(function()
        binary = payload
    end)

    if not ok or not binary then
        TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
            index = slot, success = false, error = "Décodage impossible",
        })
        return
    end

    local written = SaveResourceFile(GetCurrentResourceName(), fileName .. ".b64", binary, -1)
    if not written then
        TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
            index = slot, success = false, error = "Écriture disque refusée",
        })
        return
    end

    TriggerClientEvent("paidshop:debug:vehicleScreenshotResult", source, {
        index = slot,
        success = true,
        fileName = fileName .. ".b64",
    })
end)

RegisterNetEvent("paidshop:debug:finishVehicleScreenshotJob", function(summary)
    local source = source
    if not isAllowed(source) then return end

    local saved, failed = 0, 0
    if type(summary) == "table" then
        saved = math.floor(tonumber(summary.saved) or 0)
        failed = math.floor(tonumber(summary.failed) or 0)
    end

    jobs[source] = nil
    console.info(("paidshop: job de capture terminé (%d ok, %d échecs)"):format(saved, failed))
end)

AddEventHandler("vfw:playerDropped", function(source)
    jobs[source] = nil
end)
