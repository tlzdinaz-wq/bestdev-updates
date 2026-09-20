---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Math = {}

---@param value number
---@param numDecimalPlaces? number
---@return number
function VFW.Math.Round(value, numDecimalPlaces)
    if numDecimalPlaces then
        local power = 10 ^ numDecimalPlaces
        return math.floor((value * power) + 0.5) / power
    else
        return math.floor(value + 0.5)
    end
end

-- credit http://richard.warburton.it
-- Groupe les milliers avec le séparateur du locale actif (LOCALE.thousandsSep :
-- espace en FR, virgule en US). Fallback " " si LOCALE non chargé.
---@param value number
---@return string
function VFW.Math.GroupDigits(value)
    local sep = (LOCALE and LOCALE.thousandsSep) or " "
    local left, num, right = string.match(value, "^([^%d]*%d)(%d*)(.-)$")

    return left .. (num:reverse():gsub("(%d%d%d)", "%1" .. sep):reverse()) .. right
end

--- Formate un MONTANT selon la devise du locale actif (voir config/locale.lua).
--- Exemples : US -> "$1,000" / "$1,234.50" — FR -> "1 000 €" / "1 234,50 €".
--- NE PAS coder le symbole de devise en dur ailleurs : passer par ce helper.
---@param value number|string   Montant (les décimales sont conservées si présentes)
---@param opts? { decimals?: number, symbol?: boolean }  decimals: force le nb de décimales ; symbol=false: nombre seul, sans devise
---@return string
function VFW.Math.FormatMoney(value, opts)
    opts = opts or {}
    local loc      = LOCALE or {}
    local thousands = loc.thousandsSep or " "
    local decSep    = loc.decimalSep or "."
    local symbol    = loc.currencySymbol or "$"
    local position  = loc.currencyPosition or "prefix"

    local num = tonumber(value) or 0
    local negative = num < 0
    num = math.abs(num)

    -- Nombre de décimales : forcé si demandé, sinon 2 si le montant a une partie
    -- fractionnaire, 0 pour un entier.
    local decimals = opts.decimals
    if decimals == nil then
        decimals = (num % 1 ~= 0) and 2 or 0
    end

    -- Partie entière groupée + partie décimale avec le bon séparateur.
    local rounded = VFW.Math.Round(num, decimals)
    local intPart = math.floor(rounded)
    local intStr  = tostring(intPart)
    intStr = intStr:reverse():gsub("(%d%d%d)", "%1" .. thousands):reverse():gsub("^" .. thousands, "")

    local body = intStr
    if decimals > 0 then
        local fracStr = string.format("%." .. decimals .. "f", rounded - intPart):sub(3)
        body = intStr .. decSep .. fracStr
    end

    if opts.symbol == false then
        return (negative and "-" or "") .. body
    end

    local sign = negative and "-" or ""
    if position == "suffix" then
        return sign .. body .. " " .. symbol
    end
    return sign .. symbol .. body
end

---@param value string | number
---@return string | nil
function VFW.Math.Trim(value)
    value = tostring(value)
    return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

---@param minRange number
---@param maxRange number
---@return number
function VFW.Math.Random(minRange, maxRange)
    math.randomseed(GetGameTimer())
    return math.random(minRange or 1, maxRange or 10)
end

---@param origin vector
---@param target vector
---@return number
function VFW.Math.GetHeadingFromCoords(origin, target)
	local dx = origin.x - target.x
    local dy = origin.y - target.y

    local heading = math.deg(math.atan(dy, dx)) + 90

    return (heading + 360) % 360
end

---@param value number
---@param min number
---@param max number
---@return number
function VFW.Math.Clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    else
        return value
    end
end

function math.round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end
