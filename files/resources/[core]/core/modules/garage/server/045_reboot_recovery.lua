-- Véhicules restés « sortis » au démarrage.
--
-- Sortir un véhicule le passe à `stored = 0` ; il ne repasse à 1 qu'au rangement. Si le serveur redémarre pendant
-- qu'il roule, le véhicule disparaît du monde mais reste « sorti » en base : ni le garage (stored = 1) ni la
-- fourrière (pounded = 1) ne le proposent, il était perdu.
--
-- Au démarrage de core, chaque véhicule sorti qui n'existe plus dans le monde est remis dans son garage, avec son
-- état enregistré. Ceux qui roulent encore (simple `restart core` : les véhicules sortis sont créés en mode
-- orphelin conservé, SetEntityOrphanMode 2) ne sont pas touchés, sinon ils existeraient en double. La clé déjà dans
-- l'inventaire du joueur reste valable ; il n'en reçoit pas une deuxième à la prochaine sortie (Keys.Give).

local Vehicles = VFW.Vehicles

local function platesInWorld()
    local out = {}
    for _, vehicle in ipairs(GetAllVehicles() or {}) do
        if DoesEntityExist(vehicle) then
            local plate = Vehicles.NormalizePlate(GetVehicleNumberPlateText(vehicle))
            if plate then out[plate] = true end
        end
    end
    return out
end

local function recover()
    local rows = MySQL.query.await("SELECT plate FROM owned_vehicles WHERE stored = 0 AND pounded = 0") or {}
    if #rows == 0 then return end

    local inWorld = platesInWorld()
    local plates = {}
    for i = 1, #rows do
        local plate = rows[i].plate
        local normalized = Vehicles.NormalizePlate(plate)
        if normalized and not inWorld[normalized] then plates[#plates + 1] = plate end
    end
    if #plates == 0 then return end

    local returned = 0
    for first = 1, #plates, 200 do
        local chunk = { table.unpack(plates, first, math.min(first + 199, #plates)) }
        local marks = ("?,"):rep(#chunk):sub(1, -2)
        local changed = MySQL.update.await(
            ("UPDATE owned_vehicles SET stored = 1 WHERE stored = 0 AND pounded = 0 AND plate IN (%s)"):format(marks),
            chunk
        )
        returned = returned + (tonumber(changed) or 0)
    end
    console.info(("[garage] %d véhicule(s) resté(s) dehors avant le redémarrage remis au garage."):format(returned))
end

CreateThread(function()
    while type(MySQL) ~= "table" or not (MySQL.query and MySQL.query.await and MySQL.update and MySQL.update.await) do
        Wait(200)
    end
    MySQL.ready(function()
        local ok, err = pcall(recover)
        if not ok then console.warn("[garage] remise au garage au démarrage impossible : " .. tostring(err)) end
    end)
end)
