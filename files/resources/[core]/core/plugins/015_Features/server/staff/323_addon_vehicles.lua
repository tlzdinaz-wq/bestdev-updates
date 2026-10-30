-- Véhicules add-on du serveur, lus dans les ressources démarrées : chaque `data_file 'VEHICLE_METADATA_FILE' '<chemin>'`
-- d'un fxmanifest désigne un ou plusieurs vehicles.meta, dont on relève les <modelName>. Sert à l'onglet Add-ons de
-- Gestion > Images > Véhicules (client/staff/image_manager.lua) : une ressource démarrée ajoute ses véhicules, une
-- ressource arrêtée ou retirée les enlève. Les chemins avec * ou ** demandent la liste des fichiers du dossier de la
-- ressource (io.popen) ; si le serveur la refuse, seuls les chemins exacts sont lus.

local cache = nil
local IS_WINDOWS = package.config:sub(1, 1) == "\\"

local function staffOk(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end
    return xPlayer.hasPermission("dev") or xPlayer.hasPermission("gestion_items") or xPlayer.hasPermission("staff")
        or xPlayer.hasPermission("admin") or xPlayer.hasPermission("server_management")
end

--- Chemin déclaré dans data_file_extra : chaîne JSON ("\"stream/**/vehicles.meta\"") ou liste JSON.
local function declaredPath(extra)
    if type(extra) ~= "string" or extra == "" then return nil end
    local ok, decoded = pcall(json.decode, extra)
    if ok then
        if type(decoded) == "string" then return decoded end
        if type(decoded) == "table" and type(decoded[1]) == "string" then return decoded[1] end
    end
    return (extra:gsub('^"', ""):gsub('"$', ""))
end

--- Motif Lua équivalent au glob du manifeste (** = n'importe quels dossiers, * = un nom).
local function globPattern(glob)
    local out = glob:gsub("\\", "/"):gsub("([%^%$%(%)%%%.%[%]%+%-%?])", "%%%1")
    out = out:gsub("%*%*/", "\1"):gsub("%*%*", "\2"):gsub("%*", "[^/]*")
    out = out:gsub("\1", ".-"):gsub("\2", ".*")
    return "^" .. out .. "$"
end

--- Tous les fichiers d'une ressource, en chemins relatifs avec des « / » ; nil si le serveur ne permet pas de lister.
local function listFiles(resource)
    local root = GetResourcePath(resource)
    if type(root) ~= "string" or root == "" or not io or not io.popen then return nil end
    local cmd = IS_WINDOWS and ('dir "%s" /s /b /a-d 2>nul'):format(root:gsub("/", "\\"))
        or ("find '%s' -type f 2>/dev/null"):format(root:gsub("'", ""))
    local ok, handle = pcall(io.popen, cmd)
    if not ok or not handle then return nil end
    local base = root:gsub("\\", "/"):gsub("/+$", ""):lower()
    local files = {}
    for line in handle:lines() do
        local path = line:gsub("\\", "/")
        if path:lower():sub(1, #base) == base then
            files[#files + 1] = path:sub(#base + 2)
        end
    end
    handle:close()
    return files
end

local function modelsIn(text, into)
    if type(text) ~= "string" then return end
    for name in text:gmatch("<[Mm]odel[Nn]ame>%s*([^<%s]+)%s*</[Mm]odel[Nn]ame>") do
        into[name:lower()] = true
    end
end

local function scan()
    local models, listed, unreadable = {}, 0, {}
    for i = 0, GetNumResources() - 1 do
        local resource = GetResourceByFindIndex(i)
        if resource and GetResourceState(resource) == "started" then
            local files = false -- liste lue une seule fois, à la première étoile
            for j = 0, GetNumResourceMetadata(resource, "data_file") - 1 do
                if GetResourceMetadata(resource, "data_file", j) == "VEHICLE_METADATA_FILE" then
                    local path = declaredPath(GetResourceMetadata(resource, "data_file_extra", j))
                    if path and path:find("*", 1, true) then
                        if files == false then files = listFiles(resource) end
                        if files then
                            local pattern = globPattern(path)
                            for _, rel in ipairs(files) do
                                if rel:match(pattern) then
                                    modelsIn(LoadResourceFile(resource, rel), models)
                                    listed = listed + 1
                                end
                            end
                        else
                            unreadable[#unreadable + 1] = resource
                        end
                    elseif path then
                        modelsIn(LoadResourceFile(resource, path), models)
                        listed = listed + 1
                    end
                end
            end
        end
    end
    local list = {}
    for name in pairs(models) do list[#list + 1] = name end
    table.sort(list)
    if #unreadable > 0 then
        console.warn(("[add-ons] liste des fichiers refusée par le serveur pour %s : leurs véhicules ne sont pas détectés."):format(table.concat(unreadable, ", ")))
    end
    return { ok = #unreadable == 0 or #list > 0, models = list, files = listed, unreadable = unreadable }
end

VFW.AddonVehicles = {}

--- Liste des modèles add-on des ressources démarrées (mise en cache, relue quand une ressource démarre ou s'arrête).
function VFW.AddonVehicles.List()
    if not cache then cache = scan() end
    return cache
end

local function invalidate(resource)
    if resource ~= GetCurrentResourceName() then cache = nil end
end
AddEventHandler("onResourceStart", invalidate)
AddEventHandler("onResourceStop", invalidate)

RegisterServerCallback("vfw:server:getAddonVehicleModels", function(source)
    if not staffOk(source) then return { ok = false, models = {} } end
    return VFW.AddonVehicles.List()
end)
