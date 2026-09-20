---@meta _
---@diagnostic disable: duplicate-doc-field

local Charset = {}

for i = 48, 57 do
    table.insert(Charset, string.char(i))
end

for i = 65, 90 do
    table.insert(Charset, string.char(i))
end

for i = 97, 122 do
    table.insert(Charset, string.char(i))
end

local tconcat = table.concat

local weaponsByName = {}
local weaponsByHash = {}

CreateThread(function()
    for index, weapon in pairs(Config.Weapons) do
        weaponsByName[string.upper(weapon.name)] = index
        weaponsByHash[joaat(weapon.name)] = weapon
    end
end)

---@param length number
---@return string
function VFW.GetRandomString(length)
    if length <= 0 then return "" end
    math.randomseed(GetGameTimer())
    local parts = {}
    local charsetLen = #Charset
    for i = 1, length do
        parts[i] = Charset[math.random(1, charsetLen)]
    end
    return tconcat(parts)
end

---@return table
function VFW.GetConfig()
    return Config
end

---@param weaponName string
---@return number, table
function VFW.GetWeapon(weaponName)
    weaponName = string.upper(weaponName)

    if not weaponsByName[weaponName] then
        local newWeapon = {
            name = weaponName,
            label = weaponName,
---@class components
            components = {},
        }
        table.insert(Config.Weapons, newWeapon)

        weaponsByName[weaponName] = #Config.Weapons
        -- IMPORTANT : garder weaponsByHash synchronisé. Sans ça, une arme enregistrée
        -- dynamiquement (ex: arme créée via le menu d'items, absente de Config.Weapons)
        -- reste introuvable par VFW.GetWeaponFromHash → le rechargement serveur (qui
        -- fait un early-return si GetWeaponFromHash renvoie nil) ne fonctionne jamais.
        weaponsByHash[joaat(weaponName)] = newWeapon

        console.debug("Invalid weapon name : " .. weaponName)
    end

    local index = weaponsByName[weaponName]
    return index, Config.Weapons[index]
end

--- Enregistre une arme dans le registre (par nom ET par hash) si elle n'y est pas
--- déjà. Idempotent. Utilisé pour que les armes créées via le menu d'items (ou
--- chargées depuis la BDD) soient reconnues par tout le système d'armes, exactement
--- comme les armes natives de Config.Weapons.
---@param weaponName string
---@param weaponLabel string|nil
function VFW.RegisterWeaponItem(weaponName, weaponLabel)
    if type(weaponName) ~= "string" then return end
    local upper = string.upper(weaponName)
    if weaponsByName[upper] then return end

    local newWeapon = {
        name = upper,
        label = weaponLabel or upper,
        components = {},
    }
    table.insert(Config.Weapons, newWeapon)
    weaponsByName[upper] = #Config.Weapons
    weaponsByHash[joaat(upper)] = newWeapon
end

---@param weaponHash number
---@return table
function VFW.GetWeaponFromHash(weaponHash)
    weaponHash = type(weaponHash) == "string" and joaat(weaponHash) or weaponHash

    return weaponsByHash[weaponHash]
end

---@param byHash boolean
---@return table
function VFW.GetWeaponList(byHash)
    return byHash and weaponsByHash or Config.Weapons
end

---@param weaponName string
---@return string
function VFW.GetWeaponLabel(weaponName)
    weaponName = string.upper(weaponName)

    if not weaponsByName[weaponName] then
        console.debug("Invalid weapon name : " .. weaponName)
        return "" -- Return empty string if weapon name is invalid
    end

    local index = weaponsByName[weaponName]
    return Config.Weapons[index].label or ""
end

---@param weaponName string
---@param weaponComponent string
---@return table | nil
function VFW.GetWeaponComponent(weaponName, weaponComponent)
    weaponName = string.upper(weaponName)

    assert(weaponsByName[weaponName], "Invalid weapon name!")
    local weapon = Config.Weapons[weaponsByName[weaponName]]

    for _, component in ipairs(weapon.components) do
        if component.name == weaponComponent then
            return component
        end
    end
end

--- .DeepCopy
---@param t any
---@return any
function VFW.DeepCopy(t)
    if type(t) ~= 'table' then
        return t
    end

    local meta = getmetatable(t)
    local target = {}

    for k, v in pairs(t) do
        if type(v) == 'table' then
            target[k] = VFW.DeepCopy(v)
        else
            target[k] = v
        end
    end

    setmetatable(target, meta)

    return target
end

---@param table table
---@param nb? number
---@return string
function VFW.DumpTable(tbl, nb)
    if nb == nil then
        nb = 0
    end

    if type(tbl) == "table" then
        local parts = {}
        local indent = string.rep("    ", nb)

        parts[#parts + 1] = "{\n"
        for k, v in pairs(tbl) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end

            parts[#parts + 1] = indent .. "[" .. k .. "] = " .. VFW.DumpTable(v, nb + 1) .. ",\n"
        end

        parts[#parts + 1] = indent .. "}"
        return tconcat(parts)
    else
        return tostring(tbl)
    end
end

---@param value any
---@param numDecimalPlaces? number
---@return number
function VFW.Round(value, numDecimalPlaces)
    return VFW.Math.Round(value, numDecimalPlaces)
end

--- Formate un nombre avec des espaces comme séparateur de milliers.
---@param amount number|string
---@return string Ex: 1234567 → "1 234 567"
function VFW.Comma(amount)
    local formatted = tostring(amount)
    local k

    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1 %2')
        if k == 0 then
            break
        end
    end

    return formatted
end


---@param value string
---@param ... any
---@return boolean, string?
function VFW.ValidateType(value, ...)
    local types = { ... }
    if #types == 0 then
        return true
    end

    local mapType = {}

    for i = 1, #types, 1 do
        local validateType = types[i]
        assert(type(validateType) == "string", "bad argument types, only expected string") -- should never use anyhing else than string
        mapType[validateType] = true
    end

    local valueType = type(value)

    local matches = mapType[valueType] ~= nil

    if not matches then
        local requireTypes = table.concat(types, " or ")
        local errorMessage = ("bad value (%s expected, got %s)"):format(requireTypes, valueType)

        return false, errorMessage
    end

    return true
end

---@param ... any
---@return boolean
function VFW.AssertType(...)
    local matches, errorMessage = VFW.ValidateType(...)

    assert(matches, errorMessage)

    return matches
end

--- .DisplayTime
---@param time any
---@return any
function VFW.DisplayTime(time)
    local hours = math.floor(math.fmod(time, 86400) / 3600)
    local minutes = math.floor(math.fmod(time, 3600) / 60)
    local seconds = math.floor(math.fmod(time, 60))
    local minutesStr = minutes < 10 and "0" .. minutes or minutes
    local secondsStr = seconds < 10 and "0" .. seconds or seconds
    return hours > 0
            and hours .. ":" .. minutesStr .. ":" .. secondsStr
            or minutesStr .. ":" .. secondsStr
end

---@param zonePoints table Liste des points définissant le polygone
---@param x number Coordonnée x du point à vérifier
---@param y number Coordonnée y du point à vérifier
---@return boolean Indique si le point est à l'intérieur de la zone
function VFW.IsPlayerInsideZone(zonePoints, x, y)
    if not zonePoints or #zonePoints < 3 then
        return false
    end

    local inside = false
    local j = #zonePoints

    for i = 1, #zonePoints do
        -- Vérifier que les points sont valides
        if zonePoints[i] and zonePoints[j] then
            -- Vérification des intersections avec les côtés du polygone
            local intersect = (
                    (zonePoints[i].y > y) ~= (zonePoints[j].y > y) and
                            x < (zonePoints[j].x - zonePoints[i].x) * (y - zonePoints[i].y) /
                                    (zonePoints[j].y - zonePoints[i].y) + zonePoints[i].x
            )

            if intersect then
                inside = not inside
            end
        end

        j = i
    end

    return inside
end

local yLimitation = 1490
--- Vérifie si des coordonnées sont dans la partie sud de la map (y < 1490).
---@param coords vector3|table|number Coordonnées (ou directement une valeur y)
---@return boolean
function VFW.IsCoordsInSouth(coords)

    if type(coords) == "number" then
        return coords < yLimitation
    end

    if type(coords) == "table" and coords.y then
        return coords.y < yLimitation
    end

    return false
end

---@param val unknown
---@return boolean Vrai si val est une function ou une table avec __call
function VFW.IsFunctionReference(val)
    local typeVal = type(val)

    return typeVal == "function" or (typeVal == "table" and type(getmetatable(val)?.__call) == "function")
end

---@param conditionFunc function A function that is repeatedly called until it returns a truthy value or the timeout is exceeded.
---@param errorMessage? string Optional. If set, an error will be thrown with this message if the condition is not met within the timeout. If not set, no error will be thrown.
---@param timeoutMs? number Optional. The maximum time to wait (in milliseconds) for the condition to be met. Defaults to 1000ms.
---@return boolean, any: Returns success status and the returned value of the condition function.
function VFW.Await(conditionFunc, errorMessage, timeoutMs)
    timeoutMs = timeoutMs or 1000

    if timeoutMs < 0 then
        error("Timeout should be a positive number.")
    end

    if not VFW.IsFunctionReference(conditionFunc) then
        error("Condition Function should be a function reference.")
    end

    -- since errorMessage is optional, we only validate it if the user provided it.
    if errorMessage then
        VFW.AssertType(errorMessage, "string", "errorMessage should be a string.")
    end

    local invokingResource = GetInvokingResource()
    local startTimeMs = GetGameTimer()

    while GetGameTimer() - startTimeMs < timeoutMs do
        local result = conditionFunc()

        if result then
            return true, result
        end

        Wait(0)
    end

    if errorMessage then
        error(("[%s] -> %s"):format(invokingResource, errorMessage))
    end

    return false
end

local ignore = { ["ammo"] = true }
local bypassT = { ["weaponId"] = true, ["renamed"] = true }
--- deepCompare
---@param t1 any
---@param t2 any
---@param bypass any
---@return boolean
local function deepCompare(t1, t2, bypass)
    if t1 == t2 then
        return true
    end

    if type(t1) ~= type(t2) then
        return false
    end

    if type(t1) ~= "table" or type(t2) ~= "table" then
        return false
    end

    for k, v in pairs(t1) do
        if not ignore[k] and not (bypass and bypassT[k]) and not deepCompare(v, t2[k]) then
            return false
        end
    end

    for k, v in pairs(t2) do
        if not ignore[k] and not (bypass and bypassT[k]) and not deepCompare(v, t1[k]) then
            return false
        end
    end

    return true
end

--- .SameItem
---@param item string|table Item name or object
---@param itemCompare string|table Item name or object
---@param bypass any
---@return boolean
function VFW.SameItem(item, itemCompare, bypass)
    if item.name ~= itemCompare.name then
        return false
    end

    -- Comparer le type d'accessoire (glasses, bag, mask, etc.) si disponible
    if itemCompare.meta.type and item.meta and item.meta.type then
        if item.meta.type ~= itemCompare.meta.type then
            return false
        end
    end

    -- Comparer les items avec meta.skin (tops composites)
    if itemCompare.meta.skin or (item.meta and item.meta.skin) then
        if not itemCompare.meta.skin or not item.meta or not item.meta.skin then
            return false
        end
        for k, v in pairs(itemCompare.meta.skin) do
            if item.meta.skin[k] ~= v then
                return false
            end
        end
        for k, v in pairs(item.meta.skin) do
            if itemCompare.meta.skin[k] ~= v then
                return false
            end
        end
        return true
    end

    if not itemCompare.meta.id then
        return true
    end

    if item.meta.id ~= itemCompare.meta.id then
        return false
    end

    -- Pour les accessoires (chapeau, lunettes, etc.), la variante (texture) et la palette
    -- doivent aussi matcher. Sans ça, 2 chapeaux de même drawable mais textures différentes
    -- seraient considérés identiques et useItem/haveItem retournerait le mauvais.
    if itemCompare.meta.var ~= nil and item.meta.var ~= itemCompare.meta.var then
        return false
    end

    if itemCompare.meta.palette ~= nil and item.meta.palette ~= itemCompare.meta.palette then
        return false
    end

    return true
end

--- Génère un UUID v4 aléatoire.
---@return string UUID au format "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
function VFW.GenerateUUID()
    local random = math.random;
    local _template = type(template) == "string" and template or 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
    return string.gsub(_template, '[xy]', function(index)
        local value = (index == 'x') and random(0, 0xf) or random(8, 0xb);
        return string.format('%x', value);
    end);
end