--[[
--Created Date: Tuesday May 24th 2022
--Author:Absolute
--Made with ❤
-------
--]]

local file = nil;
local log_path = nil;
local CONSOLE_DEBUG = false;
if IsDuplicityVersion() then
	log_path = GetConvar("log_path", "logs");
	local dateHeure = os.date("%Y-%m-%d_%H-%M-%S")
	log_path = log_path .. "server_"..dateHeure..".log";

	file = io.open(log_path, "a");
	if not file then
		-- Si le fichier n'existe pas, crée-le
		file,error_message = io.open(log_path , "w+");
		if file then
		file:close();
		end
	end
end


---@param inputstr string
---@param sep string
local function split(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		table.insert(t, str)
	end
	return t
end

function __FILE__(lvl)
	local tb = split(debug.getinfo(lvl, 'S').source, "/");
	return tb[#tb];
end

local function __LINE__(lvl)
	return debug.getinfo(lvl, 'l').currentline
end

function __FUNC__(lvl)
	return debug.getinfo(lvl, 'n').name
end

local function printlinefilefunc()
	print("Line at " .. __LINE__() .. ", FILE at " .. __FILE__() .. ", in func: " .. __FUNC__())
end

---@class Logs
local Logs = {}

---@return Logs
function Logs:new()
	local self = {}
	setmetatable(self, { __index = Logs })
	self.types = {
		["INFO"] = "[^5INFO^7]",
		["WARNING"] = "[^9WARNING^7]",
		["DEBUG"] = "[^1DEBUG^7]",
		["MSG"] = "[^2MESSAGE^7]",
		["ERROR"] = "[^6ERROR^7]",
		["LOG"] = "[^2LOG^7]",
		["ESSENTIAL"] = "[^3ESSENTIAL^7]",
	}
	self.level = 0;
	self.levelOrder = {
		"ERROR",
		"WARNING",
		"ESSENTIAL",
		"INFO",
		"DEBUG",
	}
	self.pattern = "%s : %s"
	return self
end

function Logs:isInLevelDebug()
	return self.level == 0;
end

---@param msg string | table | number | boolean
---@param logType string
---@return string
function Logs:send(msg, logType, ...)

	if not self:isInLevelDebug() and logType == "DEBUG" then
		return ;
	end

	local args = { ... } or { "" }
	if #args == 0 then
		args = ""
	else
		args = tostring(json.encode(table.unpack(args)))
	end
	if msg == nil then
		return self:error("No data found")
	end
	if type(msg) == "table" then
		msg = tostring(json.encode(msg)) .. "^3"
	elseif type(msg) == "string" or type(msg) == "number" then
		msg = msg .. "^3"
	elseif type(msg) == "boolean" then
		msg = "Bool: ^1" .. tostring(msg) .. "^3"
	elseif type(msg) == "function" then
		msg = tostring(msg) .. "^3"
	else
		msg = msg .. "^3"
	end

	if IsDuplicityVersion() then
		local dateHeure = os.date("%Y-%m-%d %H:%M:%S")
		local mes = ("[%s][%s] %s %s"):format(string.upper(GetCurrentResourceName()),dateHeure, self.types[logType], msg);
		if file then
			file = io.open(log_path, "a");
			file:write(mes.."\n");
			file:close();
		end
	end
	if logType == "INFO" and CONSOLE_DEBUG then
		print(("^7[^9%s^7] %s ^3%s"):format(string.upper(GetCurrentResourceName()), self.types[logType], msg), args, "^0")
	elseif logType ~= "INFO" then
		print(("^7[^9%s^7] %s ^3%s"):format(string.upper(GetCurrentResourceName()), self.types[logType], msg), args, "^0")
	end
end


RegisterNetEvent("qx:toggleDebug",function()
	if IsDuplicityVersion() then
		local src = source
		if type(src) ~= "number" or src <= 0 then return end
		local player = VFW and VFW.GetPlayerFromId and VFW.GetPlayerFromId(src)
		if not player or not player.hasPermission("dev_tools") then return end
	end
	CONSOLE_DEBUG = not CONSOLE_DEBUG;
end)

---@param msg any
---@return string
function Logs:info(msg, ...)
	return self:send(msg, "INFO", ...)
end

---@param msg any
---@return string
function Logs:warn(msg, ...)

	return self:send(msg, "WARNING", ...)
end

function Logs:debugObject(msg)
	TriggerEvent("mdebug", msg);
end

function Logs:dump(value, indent)
	if indent == nil then
		indent = 0
	end
	local indentStr = string.rep('  ', indent)
	local valueType = type(value)
	local visited = {}

	if valueType == 'table' then
		if indent == 0 then
			print(indentStr .. '{')
		end
		for k, v in pairs(value) do
			local keyStr = tostring(k)
			if type(k) == 'string' then
				keyStr = '^2\'' .. keyStr .. '\'^7'
			end
			local valueStr
			if visited[v] then
				print(indentStr .. '  [' .. keyStr .. '] = ' .. (self:getColorValue(v) or 'nil'))
			else
				visited[v] = true
				if type(v) == "table" then
					print(indentStr .. '  [' .. keyStr .. '] = {')
					valueStr = self:dump(v, indent + 1)
				elseif type(v) == 'string' then
					print(indentStr .. '  [' .. keyStr .. '] = ^2"' .. tostring(v) .. '"^7')
				elseif type(v) == 'number' then
					print(indentStr .. '  [' .. keyStr .. '] = ^3' .. tostring(v) .. '^7')
				elseif type(v) == 'bolean' then
					print(indentStr .. '  [' .. keyStr .. '] = ^5' .. tostring(v) .. '^7')
				else
					print(indentStr .. '  [' .. keyStr .. '] = ^6' .. tostring(v) .. '^7')
				end
			end
		end
		print(indentStr .. '}')
	else
        self:colorize(value,indentStr)
	end
end

function Logs:colorize(value,indentStr)
    local valueType = type(value)
	if valueType == 'string' then
		local valueStr = tostring(value)
		valueStr = '^2"' .. valueStr .. '"^7'
		print(indentStr .. valueStr)
	elseif valueType == 'boolean' then
		print("^5" .. tostring(value) .. "^7")
	elseif valueType == 'number' then
		print("^3" .. tostring(value) .. "^7")
	elseif valueType == 'nil' then
		print("^6" .. tostring(value) .. "^7")
	elseif valueType == 'vector3' then
		print("^6" .. tostring(value) .. "^7")
	else
		print("Not supported type : " .. valueType);
	end
end

function Logs:getColorValue(value)
    local valueType = type(value)
    if valueType == 'string' then
        local valueStr = tostring(value)
        valueStr = '^2"' .. valueStr .. '"^7'
        return valueStr
    elseif valueType == 'boolean' then
        return "^5" .. tostring(value) .. "^7"
    elseif valueType == 'number' then
        return "^3" .. tostring(value) .. "^7"
    elseif valueType == 'nil' then
        return "^6" .. tostring(value) .. "^7"
    else
        return "Not supported type : " .. valueType;
    end
end

---@param msg any
---@return string
function Logs:debug(msg, ...)
	if not Config.debug then
		return
	end
	return self:send(msg, "DEBUG", ...)
end

---@param msg any
---@return string
function Logs:msg(msg, trace, ...)
	return self:send(msg, "MSG", ...)
end

---@param msg any
---@return string
function Logs:log(msg, ...)
	msg = ("File : ^4%s ^3Line : ^4%s ^3%s"):format(__FILE__(3), __LINE__(3), msg)
	return self:send(msg, "LOG", ...)
end

---@param msg any
---@return string
function Logs:error(msg, ...)
	msg = ("File : ^4%s ^3Line : ^4%s ^1%s"):format(__FILE__(3), __LINE__(3), msg)
	return self:send(msg, "ERROR", ...)
end

---@param msg any
---@return string
function Logs:essential(msg, ...)
	return self:send(msg, "ESSENTIAL", ...)
end

---@param msg any
---@return string
function Logs:test(msg, ...)
	msg = ("^7[^2%s^7] %s"):format("Test", msg)
	return self:info(msg, ...)
end

function Logs:debugLine(msg, ...)
	msg = ("File : ^4%s ^3Line : ^4%s ^1%s"):format(__FILE__(3), __LINE__(3), msg)
	return self:send(msg, "DEBUG", ...)
end

---@param msg any
---@return string
function Logs:classLoaded(msg, ...)
	msg = ("^4%s ^3loaded"):format(msg)
	return self:send(msg, "INFO", ...)
end

---Set the pattern of the logger.
---@overload fun():void
---@param string string
function Logs:pattern(value)
	self.pattern = value;
end

Console = Logs:new()

RegisterNetEvent("log:debugLine", function(msg, ...)
	Console:debugLine(msg, ...)
end)

RegisterNetEvent("log:warning", function(msg, ...)
	Console:warn(msg, ...)
end)