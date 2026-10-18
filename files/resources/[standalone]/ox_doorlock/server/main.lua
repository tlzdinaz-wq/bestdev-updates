if not LoadResourceFile(cache.resource, 'web/build/index.html') then
	error(
		'Unable to load UI. Build ox_doorlock or download the latest release.\n	^3https://github.com/overextended/ox_doorlock/releases/latest/download/ox_doorlock.zip^0')
end

if not lib.checkDependency('oxmysql', '2.4.0') then return end
if not lib.checkDependency('ox_lib', '3.14.0') then return end

lib.versionCheck('overextended/ox_doorlock')
require 'server.convert'

local utils = require 'server.utils'
local doors = {}


local function encodeData(door)
	local double = door.doors

	return json.encode({
		auto = door.auto,
		autolock = door.autolock,
		coords = door.coords,
		doors = double and {
			{
				coords = double[1].coords,
				heading = double[1].heading,
				model = double[1].model,
			},
			{
				coords = double[2].coords,
				heading = double[2].heading,
				model = double[2].model,
			},
		},
		characters = door.characters,
		groups = door.groups,
		heading = door.heading,
		items = door.items,
		lockpick = door.lockpick,
		hideUi = door.hideUi,
		holdOpen = door.holdOpen,
		lockSound = door.lockSound,
		maxDistance = door.maxDistance,
		doorRate = door.doorRate,
		model = door.model,
		state = door.state,
		unlockSound = door.unlockSound,
		passcode = door.passcode,
		lockpickDifficulty = door.lockpickDifficulty
	})
end

local function getDoor(door)
	door = type(door) == 'table' and door or doors[door]
	if not door then return false end
	return {
		id = door.id,
		name = door.name,
		state = door.state,
		coords = door.coords,
		characters = door.characters,
		groups = door.groups,
		items = door.items,
		maxDistance = door.maxDistance,
	}
end

exports('getDoor', getDoor)

exports('getAllDoors', function()
	local allDoors = {}

	for _, door in pairs(doors) do
		allDoors[#allDoors+1] = getDoor(door)
	end

	return allDoors
end)

exports('getDoorFromName', function(name)
	for _, door in pairs(doors) do
		if door.name == name then
			return getDoor(door)
		end
	end
end)

exports('editDoor', function(id, data)
	local door = doors[id]

	if door then
		for k, v in pairs(data) do
			if k ~= 'id' then
				local current = door[k]
				local t1 = type(current)
				local t2 = type(v)

				if t1 ~= 'nil' and v ~= '' and t1 ~= t2 then
					error(("Expected '%s' for door.%s, received %s (%s)"):format(t1, k, t2, v))
				end

				door[k] = v ~= '' and v or nil
			end
		end

		MySQL.update('UPDATE ox_doorlock SET name = ?, data = ? WHERE id = ?', { door.name, encodeData(door), id })
		TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, door)
	end
end)

local soundDirectory = Config.NativeAudio and 'audio/dlc_oxdoorlock/oxdoorlock' or 'web/build/sounds'
local fileFormat = Config.NativeAudio and '%.wav' or '%.ogg'
local sounds = utils.getFilesInDirectory(soundDirectory, fileFormat)

lib.callback.register('ox_doorlock:getSounds', function()
	return sounds
end)

local function createDoor(id, door, name)
	local double = door.doors
	door.id = id
	door.name = name

	if double then
		for i = 1, 2 do
			double[i].hash = joaat(('ox_door_%s_%s'):format(id, i))

			local coords = double[i].coords
			double[i].coords = vector3(coords.x, coords.y, coords.z)
		end

		if not door.coords then
			door.coords = double[1].coords - ((double[1].coords - double[2].coords) / 2)
		end
	else
		door.hash = joaat(('ox_door_%s'):format(id))
	end

	door.coords = vector3(door.coords.x, door.coords.y, door.coords.z)

	if not door.state then
		door.state = 1
	end

	if type(door.items?[1]) == 'string' then
		local items = {}

		for i = 1, #door.items do
			items[i] = {
				name = door.items[i],
				remove = false,
			}
		end

		door.items = items
		MySQL.update('UPDATE ox_doorlock SET data = ? WHERE id = ?', { encodeData(door), id })
	end

	doors[id] = door
	return door
end

local isLoaded = false
local ox_inventory = exports.ox_inventory

SetTimeout(0, function()
	if GetPlayer then return end

	function GetPlayer(_) end
end)

function RemoveItem(playerId, item, slot)
	local player = GetPlayer(playerId)

	if player then ox_inventory:RemoveItem(playerId, item, 1, nil, slot) end
end

---@param player table
---@param items string[] | { name: string, remove?: boolean, metadata?: string }[]
---@param removeItem? boolean
---@return string?
function DoesPlayerHaveItem(player, items, removeItem)
	local playerId = player.source or player.PlayerData.source

	for i = 1, #items do
		local item = items[i]
		local itemName = item.name or item
		local data = ox_inventory:Search(playerId, 'slots', itemName, item.metadata)[1]

		if data and data.count > 0 then
			if removeItem or item.remove then
				ox_inventory:RemoveItem(playerId, itemName, 1, nil, data.slot)
			end

			return itemName
		end
	end
end

local function isAuthorised(playerId, door, lockpick)
	if Config.PlayerAceAuthorised and IsPlayerAceAllowed(playerId, 'command.doorlock') then
		return true
	end

	-- e.g. add_ace group.police "doorlock.mrpd locker rooms" allow
	-- add_principal fivem:123456 group.police
	-- or add_ace identifier.fivem:123456 "doorlock.mrpd locker rooms" allow
	if IsPlayerAceAllowed(playerId, ('doorlock.%s'):format(door.name)) then
		return true
	end

	local player = GetPlayer(playerId)
	local authorised = door.passcode or false --[[@as boolean | string | nil]]

	if player then
		if lockpick then
			return DoesPlayerHaveItem(player, Config.LockpickItems)
		end

		if door.characters and table.contains(door.characters, GetCharacterId(player)) then
			return true
		end

		if door.groups then
			authorised = IsPlayerInGroup(player, door.groups) and true or nil
		end

		if not authorised and door.items then
			authorised = DoesPlayerHaveItem(player, door.items) or nil
		end

		if authorised ~= nil and door.passcode then
			authorised = door.passcode == lib.callback.await('ox_doorlock:inputPassCode', playerId)
		end
	end

	return authorised
end

local sql = LoadResourceFile(cache.resource, 'sql/ox_doorlock.sql')

if sql then MySQL.query(sql) end

MySQL.ready(function()
	while Config.DoorList do Wait(100) end

	local response = MySQL.query.await('SELECT `id`, `name`, `data` FROM `ox_doorlock`')

	for i = 1, #response do
		local door = response[i]
		createDoor(door.id, json.decode(door.data), door.name)
	end

	isLoaded = true

	TriggerEvent('ox_doorlock:loaded')
end)

---@param id number
---@param state 0 | 1 | boolean
---@param lockpick? boolean
---@return boolean
local function setDoorState(id, state, lockpick)
	local door = doors[id]

	state = (state == 1 or state == 0) and state or (state and 1 or 0)

	if door then
		local authorised = not source or source == '' or isAuthorised(source, door, lockpick)

		if authorised then
			door.state = state
			TriggerClientEvent('ox_doorlock:setState', -1, id, state, source)

			if door.autolock and state == 0 then
				SetTimeout(door.autolock * 1000, function()
					if door.state ~= 1 then
						door.state = 1

						TriggerClientEvent('ox_doorlock:setState', -1, id, door.state)
						TriggerEvent('ox_doorlock:stateChanged', nil, door.id, door.state == 1)
					end
				end)
			end

			TriggerEvent('ox_doorlock:stateChanged', source, door.id, state == 1,
				type(authorised) == 'string' and authorised)

			return true
		end

		if source then
			lib.notify(source,
				{ type = 'error', icon = 'lock', description = state == 0 and 'cannot_unlock' or 'cannot_lock' })
		end
	end

	return false
end

RegisterNetEvent('ox_doorlock:setState', setDoorState)
exports('setDoorState', setDoorState)

lib.callback.register('ox_doorlock:getDoors', function()
	while not isLoaded do Wait(100) end

	return doors, sounds
end)

RegisterNetEvent('ox_doorlock:editDoorlock', function(id, data)
	if IsPlayerAceAllowed(source, 'command.doorlock') then
		if data then
			if not data.coords then
				local double = data.doors
				data.coords = double[1].coords - ((double[1].coords - double[2].coords) / 2)
			end

			if not data.name then
				data.name = tostring(data.coords)
			end
		end

		if id then
			if data then
				MySQL.update('UPDATE ox_doorlock SET name = ?, data = ? WHERE id = ?',
					{ data.name, encodeData(data), id })
			else
				MySQL.update('DELETE FROM ox_doorlock WHERE id = ?', { id })
			end

			doors[id] = data
			TriggerClientEvent('ox_doorlock:editDoorlock', -1, id, data)
		else
			local insertId = MySQL.insert.await('INSERT INTO ox_doorlock (name, data) VALUES (?, ?)',
				{ data.name, encodeData(data) })
			local door = createDoor(insertId, data, data.name)

			TriggerClientEvent('ox_doorlock:setState', -1, door.id, door.state, false, door)
		end
	end
end)

RegisterNetEvent('ox_doorlock:breakLockpick', function()
	local player = GetPlayer(source)
	return player and DoesPlayerHaveItem(player, Config.LockpickItems, true)
end)

lib.addCommand('doorlock', {
	help = locale('create_modify_lock'),
	params = {
		{
			name = 'closest',
			help = locale('command_closest'),
			optional = true,
		},
	},
	restricted = Config.CommandPrincipal
}, function(source, args)
	TriggerClientEvent('ox_doorlock:triggeredCommand', source, args.closest)
end)

-- ══════════════════════════════════════════════════════════════════════════
-- Menu staff « Gérer les accès des portes » (core)
--
-- Le menu builder du core — plugins/015_Features/client/staff/menu/builders.lua —
-- appelle quatre points d'entrée qui n'avaient jamais été écrits ici : ouvrir
-- l'éditeur, lister les portes, enregistrer les accès par métier ou faction,
-- enregistrer les accès par UUID. La liste échouait sur « callback
-- 'ox_doorlock:getAllDoorsForBuilder' does not exist » et le menu restait vide ;
-- les deux enregistrements partaient dans le vide sans rien dire.
--
-- Le menu raisonne en accès { name, grade, type } ; ox_doorlock ne connaît que
-- door.groups, une table { [nom] = grade }. La conversion se fait ici.
-- ══════════════════════════════════════════════════════════════════════════

local BUILDER_PERMISSIONS <const> = { 'doorlock_builder', 'doorlock', 'dev', 'admin' }

---Le principal ace de la commande reste valable, mais le staff du serveur est
---reconnu par ses permissions : il n'est pas forcément dans group.admin.
---@param playerId number
---@return boolean
local function isBuilder(playerId)
	if IsPlayerAceAllowed(playerId, 'command.doorlock') then return true end

	local player = GetPlayer and GetPlayer(playerId)
	if not player or not player.hasPermission then return false end

	for i = 1, #BUILDER_PERMISSIONS do
		if player.hasPermission(BUILDER_PERMISSIONS[i]) then return true end
	end

	return false
end

-- door.groups ne retient que le nom et le grade, jamais la nature du groupe. Le menu,
-- lui, sépare métiers et factions. On retrouve la nature au nom : ce qui figure dans
-- la table des métiers est un métier, le reste est une faction.
local jobNames

---@param name string
---@return boolean
local function isJobName(name)
	if not jobNames then
		jobNames = {}

		local rows = MySQL.query.await('SELECT `name` FROM `jobs`') or {}
		for i = 1, #rows do jobNames[rows[i].name] = true end
	end

	return jobNames[name] == true
end

---@param groups table|nil
---@return { name: string, grade: number, type: string }[]
local function groupsToAccess(groups)
	local access = {}
	if type(groups) ~= 'table' then return access end

	-- ox_doorlock accepte aussi une simple liste de noms, sans grade.
	if table.type(groups) == 'array' then
		for i = 1, #groups do
			local name = groups[i]
			access[#access + 1] = { name = name, grade = 0, type = isJobName(name) and 'job' or 'faction' }
		end

		return access
	end

	for name, grade in pairs(groups) do
		access[#access + 1] = {
			name = name,
			grade = tonumber(grade) or 0,
			type = isJobName(name) and 'job' or 'faction',
		}
	end

	return access
end

---@param access table|nil
---@return table|nil groups  nil quand la porte redevient publique.
local function accessToGroups(access)
	if type(access) ~= 'table' then return nil end

	local groups = {}
	for i = 1, #access do
		local entry = access[i]
		if type(entry) == 'table' and type(entry.name) == 'string' and entry.name ~= '' then
			groups[entry.name] = math.floor(tonumber(entry.grade) or 0)
		end
	end

	return next(groups) and groups or nil
end

---Enregistre la porte et la pousse à tous les clients, comme le fait l'éditeur.
---@param door table
local function saveDoor(door)
	MySQL.update('UPDATE ox_doorlock SET data = ? WHERE id = ?', { encodeData(door), door.id })
	TriggerClientEvent('ox_doorlock:editDoorlock', -1, door.id, door)
end

lib.callback.register('ox_doorlock:getAllDoorsForBuilder', function(source)
	if not isBuilder(source) then return {} end

	local list = {}

	for _, door in pairs(doors) do
		list[#list + 1] = {
			id = door.id,
			name = door.name,
			state = door.state,
			coords = door.coords,
			characters = door.characters or {},
			vfw_access = groupsToAccess(door.groups),
		}
	end

	return list
end)

RegisterNetEvent('ox_doorlock:openEditor', function(closest)
	local source = source
	if not isBuilder(source) then return end

	TriggerClientEvent('ox_doorlock:triggeredCommand', source, closest == true or nil)
end)

RegisterNetEvent('ox_doorlock:updateVfwAccess', function(id, access)
	local source = source
	if not isBuilder(source) then return end

	local door = doors[tonumber(id) or 0]
	if not door then return end

	door.groups = accessToGroups(access)
	saveDoor(door)
end)

RegisterNetEvent('ox_doorlock:updateCharacters', function(id, characters)
	local source = source
	if not isBuilder(source) then return end

	local door = doors[tonumber(id) or 0]
	if not door then return end

	local list = {}
	if type(characters) == 'table' then
		for i = 1, #characters do
			local uuid = tonumber(characters[i])
			if uuid then list[#list + 1] = uuid end
		end
	end

	door.characters = next(list) and list or nil
	saveDoor(door)
end)
