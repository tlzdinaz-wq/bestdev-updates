----
---- Created Date: [2025-03-02 00:54:55]
---- Author: Johnny
----
---- File: [client.lua]
----

-- Adapte a la base Aurora : ce script etait ecrit pour ESX, qui n'est pas le
-- framework d'ici. La seule chose qu'il demandait a ESX etait d'afficher une
-- notification ; elle passe maintenant par celle de la base.

local mediaPlayers = {}
local localMediaPlayers = {}

local usableEntities = {}
local personalMediaPlayers = {}

local baseVolume = 50
local statusIsShown = false
local uiIsOpen = false
local syncIsEnabled = true
local tooltipsEnabled = true
local staticEmittersDisabled = false
local disableIdleCam = false

local permissions = {}
permissions.interact = false
permissions.anyEntity = false
permissions.customUrl = false
permissions.anyUrl = false
permissions.manage = false

RegisterNetEvent("pmms:sync")
RegisterNetEvent("pmms:start")
RegisterNetEvent("pmms:play")
RegisterNetEvent("pmms:stop")
RegisterNetEvent("pmms:showControls")
RegisterNetEvent("pmms:toggleStatus")
RegisterNetEvent("pmms:error")
RegisterNetEvent("pmms:init")
RegisterNetEvent("pmms:reset")
RegisterNetEvent("pmms:startClosestMediaPlayer")
RegisterNetEvent("pmms:pauseClosestMediaPlayer")
RegisterNetEvent("pmms:stopClosestMediaPlayer")
RegisterNetEvent("pmms:listPresets")
RegisterNetEvent("pmms:setBaseVolume")
RegisterNetEvent("pmms:showBaseVolume")
RegisterNetEvent("pmms:loadPermissions")
RegisterNetEvent("pmms:loadSettings")
RegisterNetEvent("pmms:notify")
RegisterNetEvent("pmms:enableEntity")
RegisterNetEvent("pmms:disableEntity")
RegisterNetEvent("pmms:refreshPermissions")

local function notify(args)
	if type(args) ~= "table" then
		args = {}
	end

	TriggerEvent("vfw:showNotification", {
		type = "INFO",
		subtitle = "Musique",
		content = tostring(args.text or ""),
	})
end

local function doesEntityExist(entity)
	-- Les props du décor (télés murales) ont parfois un handle élevé :
	-- l'ancien plafond les jetait, donc la télé à côté n'apparaissait jamais.
	return type(entity) == "number" and entity ~= 0 and DoesEntityExist(entity)
end

local entityEnumerator = {
	__gc = function(enum)
		if enum.destructor and enum.handle then
			enum.destructor(enum.handle)
		end
		enum.destructor = nil
		enum.handle = nil
	end
}

local function enumerateEntities(firstFunc, nextFunc, endFunc)
	return coroutine.wrap(function()
		local iter, id = firstFunc()

		if not id or id == 0 then
			endFunc(iter)
			return
		end

		local enum = {handle = iter, destructor = endFunc}
		setmetatable(enum, entityEnumerator)

		local next = true
		repeat
			coroutine.yield(id)
			next, id = nextFunc(iter)
		until not next

		enum.destructor, enum.handle = nil, nil
		endFunc(iter)
	end)
end

local function enumerateVehicles()
	return enumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end

local function enumerateObjects()
	return enumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

local function isMediaPlayer(entity)
	local model = GetEntityModel(entity)

	if not (permissions.anyEntity or usableEntities[entity]) then
		return false
	end

	return MediaConfig.models[model] ~= nil
end

local function getHandle(entity)
	return NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or entity
end

local function findHandle(entity)
	if NetworkGetEntityIsNetworked(entity) then
		local netId = NetworkGetNetworkIdFromEntity(entity)

		if mediaPlayers[netId] then
			return netId
		end
	end

	local handle = GetHandleFromCoords(GetEntityCoords(entity))

	if mediaPlayers[handle] then
		return handle
	end

	return nil
end

local function forEachMediaPlayer(func)
	for object in enumerateObjects() do
		if isMediaPlayer(object) then
			func(object)
		end
	end

	if MediaConfig.allowPlayingFromVehicles then
		for vehicle in enumerateVehicles() do
			func(vehicle)
		end
	end
end

local function getClosestMediaPlayerEntity(centre, radius, listenerPos, range)
	if listenerPos and range and #(centre - listenerPos) > range then
		return nil
	end

	local min
	local closest

	forEachMediaPlayer(function(entity)
		local coords = GetEntityCoords(entity)
		local distance = #(centre - coords)

		if distance <= radius and (not min or distance < min) then
			min = distance
			closest = entity
		end
	end)

	return closest
end

local function getClosestMediaPlayer()
	return getClosestMediaPlayerEntity(GetEntityCoords(PlayerPedId()), MediaConfig.maxDiscoveryDistance)
end

local function getEntityLabel(handle, entity)
	local defaultMediaPlayer = GetDefaultMediaPlayer(MediaConfig.defaultMediaPlayers, GetEntityCoords(entity))

	if defaultMediaPlayer and defaultMediaPlayer.label then
		return defaultMediaPlayer.label
	else
		local entityType = GetEntityType(entity)
		local model = GetEntityModel(entity)

		if model and MediaConfig.models[model] and MediaConfig.models[model].label then
			return MediaConfig.models[model].label
		elseif entityType == 2 then
			if model then
				local displayName = GetDisplayNameFromVehicleModel(model)
				local labelText = GetLabelText(displayName)

				if labelText == "NULL" then
					return displayName
				else
					return labelText
				end
			else
				return "Veh " .. tostring(handle)
			end
		elseif entityType == 3 then
			return "Obj " .. tostring(handle)
		elseif handle then
			return tostring(handle)
		else
			return false
		end
	end
end

local function getCoordsLabel(handle, coords)
	local defaultMediaPlayer = GetDefaultMediaPlayer(MediaConfig.defaultMediaPlayers, coords)

	if defaultMediaPlayer and defaultMediaPlayer.label then
		return defaultMediaPlayer.label
	elseif handle then
		return tostring(handle)
	else
		return false
	end
end

local function asVector3(value)
	if type(value) == "vector3" then
		return value
	end
	if type(value) == "table" and value.x and value.y and value.z then
		return vector3(value.x + 0.0, value.y + 0.0, value.z + 0.0)
	end
end

-- Le nom d'écran enregistré dans la config n'est pas toujours celui que le
-- modèle accepte. On essaie ceux qui se lient vraiment, sinon la télé reste noire.
local SCREEN_TARGETS = {
	"tvscreen",
	"script_rt_tvscreen",
	"script_rt_ex_tvscreen",
	"ex_tvscreen",
	"cinscreen",
	"Big_Disp",
	"big_disp",
	"ECG",
}

local function resolveRenderTarget(model, preferred)
	if not model or model == 0 then
		return preferred
	end

	local tried = {}
	local function consider(name)
		if type(name) ~= "string" or name == "" or tried[name] then
			return nil
		end
		tried[name] = true

		if not IsNamedRendertargetRegistered(name) then
			RegisterNamedRendertarget(name, false)
		end
		LinkNamedRendertarget(model)
		if IsNamedRendertargetLinked(model) then
			return name
		end
		ReleaseNamedRendertarget(name)
		return nil
	end

	local found = consider(preferred)
	if found then
		return found
	end
	for i = 1, #SCREEN_TARGETS do
		found = consider(SCREEN_TARGETS[i])
		if found then
			return found
		end
	end
	return preferred or "tvscreen"
end

local function startMediaPlayer(handle, options)
	if not options.offset then
		options.offset = "0"
	end

	options.volume = Clamp(options.volume, 0, 100, 100)
	options.videoSize = Clamp(options.videoSize, 10, 100, MediaConfig.defaultVideoSize)

	if options.filter == nil then
		options.filter = false
	end

	if options.attenuation then
		options.attenuation.sameRoom = Clamp(options.attenuation.sameRoom, 0.0, 10.0, MediaConfig.defaultSameRoomAttenuation)
		options.attenuation.diffRoom = Clamp(options.attenuation.diffRoom, 0.0, 10.0, MediaConfig.defaultDiffRoomAttenuation)
	else
		options.attenuation = {
			sameRoom = MediaConfig.defaultSameRoomAttenuation,
			diffRoom = MediaConfig.defaultDiffRoomAttenuation
		}
	end

	options.diffRoomVolume = Clamp(options.diffRoomVolume, 0.0, 1.0, MediaConfig.defaultDiffRoomVolume)
	options.range = Clamp(options.range, 0, MediaConfig.maxRange, MediaConfig.defaultRange)

	if NetworkDoesNetworkIdExist(handle) then
		local entity = NetworkGetEntityFromNetworkId(handle)

		options.model = GetEntityModel(entity)

		if options.model and options.model ~= 0 then
			local configured = MediaConfig.models[options.model] and MediaConfig.models[options.model].renderTarget
			options.renderTarget = resolveRenderTarget(options.model, configured or options.renderTarget)
			if MediaConfig.models[options.model] and options.renderTarget then
				MediaConfig.models[options.model].renderTarget = options.renderTarget
			end
		end

		if not options.label then
			options.label = getEntityLabel(handle, entity)
		end

		if options.isVehicle == nil then
			if MediaConfig.models[options.model] then
				options.isVehicle = MediaConfig.models[options.model].isVehicle
			else
				options.isVehicle = IsEntityAVehicle(entity)
			end
		end
	elseif doesEntityExist(handle) then
		if not options.coords then
			options.coords = GetEntityCoords(handle)
		end

		options.model = GetEntityModel(handle)

		if options.model and options.model ~= 0 then
			local configured = MediaConfig.models[options.model] and MediaConfig.models[options.model].renderTarget
			options.renderTarget = resolveRenderTarget(options.model, configured or options.renderTarget)
			if MediaConfig.models[options.model] and options.renderTarget then
				MediaConfig.models[options.model].renderTarget = options.renderTarget
			end
		end

		if not options.label then
			options.label = getEntityLabel(handle, handle)
		end

		if options.isVehicle == nil then
			if MediaConfig.models[options.model] then
				options.isVehicle = MediaConfig.models[options.model].isVehicle
			else
				options.isVehicle = IsEntityAVehicle(handle)
			end
		end

		handle = false
	elseif options.coords then
		if not options.label then
			options.label = getCoordsLabel(handle, options.coords)
		end

		handle = false
	end

	TriggerServerEvent("pmms:start", handle, options)
end

local function startClosestMediaPlayer(options)
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if MediaConfig.showNotifications then
			notify{text = "~r~Erreur~s~  Aucun lecteur à proximité"}
		end

		return
	end

	startMediaPlayer(getHandle(mediaPlayer), options)
end

local function pauseMediaPlayer(handle)
	TriggerServerEvent("pmms:pause", handle)
end

local function pauseClosestMediaPlayer()
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if MediaConfig.showNotifications then
			notify{text = "~r~Erreur~s~  Aucun lecteur à proximité"}
		end

		return
	end

	pauseMediaPlayer(findHandle(mediaPlayer))
end

local function stopMediaPlayer(handle)
	TriggerServerEvent("pmms:stop", handle)
end

local function stopClosestMediaPlayer()
	local mediaPlayer = getClosestMediaPlayer()

	if not mediaPlayer then
		if MediaConfig.showNotifications then
			notify{text = "~r~Erreur~s~  Aucun lecteur à proximité"}
		end

		return
	end

	stopMediaPlayer(findHandle(mediaPlayer))
end

local function getListenerAndViewerInfo()
	local cam = GetRenderingCam()
	local ped = PlayerPedId()

	local listenerCoords, viewerCoords, viewerFov

	if cam == -1 then
		if IsPedDeadOrDying(ped) then
			listenerCoords = GetGameplayCamCoord()
			viewerCoords = listenerCoords
		else
			listenerCoords = GetEntityCoords(ped)
			viewerCoords = GetGameplayCamCoord()
		end

		viewerFov = GetGameplayCamFov()
	else
		listenerCoords = GetCamCoord(cam)
		viewerCoords = listenerCoords
		viewerFov = GetCamFov(cam)
	end

	return ped, listenerCoords, viewerCoords, viewerFov
end

local function sortByDistance(a, b)
	if a.distance < 0 then
		return false
	elseif b.distance < 0 then
		return true
	else
		return a.distance < b.distance
	end
end

local function isInSameRoom(entity1, entity2)
	local interior1 = GetInteriorFromEntity(entity1)
	local interior2 = GetInteriorFromEntity(entity2)

	if interior1 ~= interior2 then
		return false
	end

	local roomHash1 = GetRoomKeyFromEntity(entity1)
	local roomHash2 = GetRoomKeyFromEntity(entity2)

	if roomHash1 ~= roomHash2 then
		return false
	end

	return true
end

local function listPresets()
	local presets = {}

	for preset, info in pairs(MediaConfig.presets) do
		table.insert(presets, preset)
	end

	if #presets == 0 then
		notify{text = "Aucun préréglage disponible"}
	else
		table.sort(presets)

		for _, preset in ipairs(presets) do
			TriggerEvent("chat:addMessage", {
				args = {preset, MediaConfig.presets[preset].title}
			})
		end
	end
end

local function lookAtObject(maxDistance)
	local rot = GetGameplayCamRot(2)
	local cam = GetGameplayCamCoord()
	local rx, rz = math.rad(rot.x), math.rad(rot.z)
	local dir = vector3(
		-math.sin(rz) * math.abs(math.cos(rx)),
		math.cos(rz) * math.abs(math.cos(rx)),
		math.sin(rx)
	)
	local dest = cam + dir * maxDistance
	local ray = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, 17, PlayerPedId(), 7)
	local status, hit, _, _, entity = GetShapeTestResult(ray)
	local spins = 0
	while status == 1 and spins < 6 do
		Wait(0)
		status, hit, _, _, entity = GetShapeTestResult(ray)
		spins = spins + 1
	end
	if hit == 1 and doesEntityExist(entity) and GetEntityType(entity) == 3 then
		return entity
	end
end

local function ensureScreenModel(entity)
	local model = GetEntityModel(entity)
	if not model or model == 0 or type(MediaConfig.models) ~= "table" then
		return false
	end
	if MediaConfig.models[model] then
		return true
	end

	local name = ""
	local ok, archetype = pcall(GetEntityArchetypeName, entity)
	if ok and type(archetype) == "string" then
		name = archetype:lower()
	end
	if name:find("tv", 1, true) or name:find("screen", 1, true) or name:find("monitor", 1, true) or name:find("cinema", 1, true) then
		MediaConfig.models[model] = {
			label = "TV",
			renderTarget = "tvscreen",
		}
		return true
	end
	return false
end

-- FindFirstObject ignore les props du mapping (télé au mur). GetClosestObjectOfType
-- les voit, et le rayon de visée attrape celle que le joueur regarde.
local function discoverNearbyScreens(centre, remember)
	if type(MediaConfig.models) ~= "table" then
		return
	end

	local radius = MediaConfig.maxDiscoveryDistance or 30.0
	for model, _ in pairs(MediaConfig.models) do
		if type(model) == "number" then
			local obj = GetClosestObjectOfType(centre.x, centre.y, centre.z, radius, model, false, false, false)
			if obj and obj ~= 0 then
				remember(obj, false)
			end
		end
	end

	local looked = lookAtObject(15.0)
	if looked and ensureScreenModel(looked) then
		remember(looked, true)
	end
end

local function updateUi()
	local playerPed = PlayerPedId()
	local pos = GetEntityCoords(playerPed)

	local activeMediaPlayers = {}

	for handle, info in pairs(mediaPlayers) do
		local entity
		local entityExists

		if info.coords then
			entity = localMediaPlayers[handle]
		elseif NetworkDoesNetworkIdExist(handle) then
			entity = NetworkGetEntityFromNetworkId(handle)
		end

		local entityExists = doesEntityExist(entity)

		local mediaPos

		if entityExists then
			mediaPos = GetEntityCoords(entity)
		elseif info.coords then
			mediaPos = info.coords
		end

		if mediaPos then
			local distance = #(pos - mediaPos)

			if permissions.manage or distance <= info.range then
				local label

				if info.label then
					label = info.label
				elseif entityExists then
					label = getEntityLabel(handle, entity)
				else
					label = getCoordsLabel(handle, mediaPos)
				end

				local model

				if info.model then
					model = info.model
				elseif entityExists then
					model = GetEntityModel(entity)
				end

				-- Can the user interact with this particular media player?
				local canInteract = permissions.manage or
					(permissions.interact and
						(not entityExists or (permissions.anyEntity or usableEntities[entity] ~= nil)))

				table.insert(activeMediaPlayers, {
					handle = handle,
					info = info,
					distance = distance,
					label = label,
					canInteract = canInteract
				})
			end
		else
			if permissions.manage then
				table.insert(activeMediaPlayers, {
					handle = handle,
					info = info,
					distance = -1,
					canInteract = true
				})
			end
		end
	end

	table.sort(activeMediaPlayers, sortByDistance)

	local usableMediaPlayers = {}

	if uiIsOpen then
		local uniqueUsableMediaPlayers = {}

		local function rememberUsable(entity, force)
			if not doesEntityExist(entity) then
				return
			end

			local mediaPos = GetEntityCoords(entity)
			local clHandle = getHandle(entity)
			if not clHandle then
				return
			end

			local svHandle = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or GetHandleFromCoords(mediaPos)
			local distance = #(pos - mediaPos)
			local isNearby = distance <= MediaConfig.maxDiscoveryDistance
			local isActive = mediaPlayers[svHandle] ~= nil

			if force or isNearby or (permissions.manage and isActive) then
				uniqueUsableMediaPlayers[clHandle] = {
					distance = distance,
					label = getEntityLabel(clHandle, entity),
					active = isActive
				}
			end
		end

		forEachMediaPlayer(function(entity)
			rememberUsable(entity, false)
		end)

		discoverNearbyScreens(pos, rememberUsable)

		-- Toujours proposer le véhicule du joueur : l'énumération CEF peut
		-- rater le véhicule courant, et le menu « flèche » restait alors vide.
		local ped = PlayerPedId()
		local currentVehicle = GetVehiclePedIsIn(ped, false)
		if currentVehicle ~= 0 then
			rememberUsable(currentVehicle, true)
		else
			local closestVehicle = GetClosestVehicle(pos.x, pos.y, pos.z, 6.0, 0, 71)
			if closestVehicle ~= 0 then
				rememberUsable(closestVehicle, true)
			end
		end

		for _, mediaPlayer in ipairs(activeMediaPlayers) do
			if mediaPlayer.info.scaleform and mediaPlayer.info.scaleform.standalone and not uniqueUsableMediaPlayers[mediaPlayer.handle] then
				uniqueUsableMediaPlayers[mediaPlayer.handle] = {
					distance = mediaPlayer.distance,
					label = mediaPlayer.label,
					active = true
				}
			end
		end

		for _, mediaPlayer in ipairs(MediaConfig.defaultMediaPlayers) do
			if mediaPlayer.scaleform and mediaPlayer.scaleform.standalone then
				local svHandle = GetHandleFromCoords(mediaPlayer.position)

				if not uniqueUsableMediaPlayers[svHandle] then
					local distance = #(pos - mediaPlayer.position)
					local isNearby = distance <= MediaConfig.maxDiscoveryDistance
					local label = getCoordsLabel(svHandle, mediaPlayer.position)
					local isActive = mediaPlayers[svHandle] ~= nil

					if isNearby or (permissions.manage and isActive) then
						uniqueUsableMediaPlayers[svHandle] = {
							distance = distance,
							label = label,
							active = isActive,
							standaloneScaleform = true,
							coords = mediaPlayer.position
						}
					end
				end
			end
		end

		for handle, info in pairs(uniqueUsableMediaPlayers) do
			table.insert(usableMediaPlayers, {
				handle = handle,
				distance = info.distance,
				label = info.label,
				active = info.active,
				standaloneScaleform = info.standaloneScaleform,
				coords = info.coords
			})
		end

		table.sort(usableMediaPlayers, sortByDistance)
	end

	SendNUIMessage({
		type = "updateUi",
		uiIsOpen = uiIsOpen,
		activeMediaPlayers = json.encode(activeMediaPlayers),
		usableMediaPlayers = json.encode(usableMediaPlayers),
		presets = json.encode(MediaConfig.presets),
		maxDiscoveryDistance = MediaConfig.maxDiscoveryDistance,
		permissions = permissions,
		baseVolume = baseVolume
	})
end

local function createMediaPlayerEntity(options, networked)
	local model = options.model or MediaConfig.defaultModel

	if type(model) == "string" then
		model = GetHashKey(model)
	end

	if not IsModelInCdimage(model) then
		print("Invalid model: " .. tostring(model))
		return
	end

	RequestModel(model)

	while not HasModelLoaded(model) do
		Citizen.Wait(0)
	end

	local entity = CreateObjectNoOffset(model, options.position, networked, networked, false, false)

	SetModelAsNoLongerNeeded(model)

	if options.rotation then
		SetEntityRotation(entity, options.rotation, 2)
	end

	if options.invisible then
		SetEntityVisible(entity, false)
		SetEntityCollision(entity, false, false)
	end

	return entity
end

local function createDefaultMediaPlayer(mediaPlayer)
	mediaPlayer.handle = createMediaPlayerEntity(mediaPlayer, false)
end

local function setMediaPlayerStartTime(handle, time)
	TriggerServerEvent("pmms:setStartTime", handle, time)
end

local function lockMediaPlayer(handle)
	TriggerServerEvent("pmms:lock", handle)
end

local function unlockMediaPlayer(handle)
	TriggerServerEvent("pmms:unlock", handle)
end

local function setBaseVolume(volume)
	baseVolume = Clamp(volume, 0, 100, 100)
	SetResourceKvp("baseVolume", tostring(baseVolume))
end

local function toggleStatus()
	SendNUIMessage({
		type = "toggleStatus"
	})
	statusIsShown = not statusIsShown
	SetResourceKvpInt("showStatus", statusIsShown and 1 or 0)
end

local function loadSettings()
	local volume = GetResourceKvpString("baseVolume")

	if volume then
		baseVolume = tonumber(volume)
	end

	local showStatus = GetResourceKvpInt("showStatus")

	if showStatus == 1 then
		toggleStatus()
	end

	tooltipsEnabled = GetResourceKvpString("tooltipsEnabled") ~= "no"
end

local function enableVideo(handle)
	TriggerServerEvent("pmms:enableVideo", handle)
end

local function disableVideo(handle)
	TriggerServerEvent("pmms:disableVideo", handle)
end

local function isPauseMenuOrMapActive()
	return IsPauseMenuActive()
end

local function copyMediaPlayer(oldHandle, newHandle)
	if NetworkDoesNetworkIdExist(newHandle) then
		TriggerServerEvent("pmms:copy", oldHandle, newHandle)
	else
		local coords = GetEntityCoords(newHandle)
		TriggerServerEvent("pmms:copy", oldHandle, false, coords)
	end
end

local function getLocalMediaPlayer(coords, listenerPos, range)
	local handle = GetHandleFromCoords(coords)

	if not doesEntityExist(localMediaPlayers[handle]) then
		localMediaPlayers[handle] = getClosestMediaPlayerEntity(coords, 1.0, listenerPos, range)
	end

	return localMediaPlayers[handle]
end

local function getEntityModelAndRenderTarget(handle)
	local entity
	local coords = asVector3(handle)

	if coords then
		entity = getLocalMediaPlayer(coords, GetEntityCoords(PlayerPedId()), MediaConfig.maxRange)
	elseif NetworkDoesNetworkIdExist(handle) then
		entity = NetworkGetEntityFromNetworkId(handle)
	elseif doesEntityExist(handle) then
		entity = handle
	else
		return
	end

	if not doesEntityExist(entity) then
		return
	end

	local model = GetEntityModel(entity)

	if not model or model == 0 then
		return
	end

	local renderTarget = MediaConfig.models[model] and MediaConfig.models[model].renderTarget
	renderTarget = resolveRenderTarget(model, renderTarget)
	return entity, model, renderTarget
end

local function sendMediaMessage(handle, coords, data)
	local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

	if not duiBrowser then
		local scaleform

		if mediaPlayers[handle] and mediaPlayers[handle].scaleform then
			scaleform = mediaPlayers[handle].scaleform
		else
			scaleform = data.options and data.options.scaleform
		end

		local entity, model, renderTarget = getEntityModelAndRenderTarget(coords or handle)

		local mediaPos

		if entity then
			mediaPos = GetEntityCoords(entity)
		elseif mediaPlayers[handle] then
			mediaPos = asVector3(mediaPlayers[handle].coords) or mediaPlayers[handle].coords
			model = model or mediaPlayers[handle].model
			renderTarget = renderTarget or mediaPlayers[handle].renderTarget
		elseif data.options and data.options.coords then
			mediaPos = asVector3(data.options.coords) or data.options.coords
		end

		-- La télé locale n'est pas en réseau : le modèle et l'écran voyagent
		-- dans les options, sinon le DUI n'est jamais créé et seul le son sort.
		if data.options then
			model = model or data.options.model
			renderTarget = renderTarget or data.options.renderTarget
			if (not mediaPos) and data.options.coords then
				mediaPos = asVector3(data.options.coords)
			end
		end

		if model and not renderTarget then
			renderTarget = resolveRenderTarget(model, nil)
		end

		if mediaPos and (model or scaleform) and data.options then
			local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

			if #(viewerPos - mediaPos) < (data.range or MediaConfig.maxRange) then
				duiBrowser = DuiBrowser:new(handle, model, renderTarget, scaleform, data.options.url)
			end
		end
	end

	if duiBrowser then
		if data.options and data.options.scaleform then
			duiBrowser:setScaleform(data.options.scaleform)
		end

		duiBrowser:sendMessage(data)
	end
end

local function getSvHandle(handle)
	if NetworkDoesNetworkIdExist(handle) then
		return handle
	elseif doesEntityExist(handle) then
		return GetHandleFromCoords(GetEntityCoords(handle))
	else
		return handle
	end
end

local function enableEntity(entity)
	usableEntities[entity] = true
end

local function disableEntity(entity)
	usableEntities[entity] = nil

	stopMediaPlayer(findHandle(entity))
end

local function createMediaPlayer(options)
	local entity = createMediaPlayerEntity(options, true)

	personalMediaPlayers[entity] = true
	enableEntity(entity)

	return entity
end

local function deleteMediaPlayer(entity)
	personalMediaPlayers[entity] = nil

	disableEntity(entity)

	DeleteEntity(entity)
end

local function disableStaticEmitters()
	for _, emitter in ipairs(StaticEmitters) do
		SetStaticEmitterEnabled(emitter.name, false)
	end
end

local function restoreStaticEmitters()
	for _, emitter in ipairs(StaticEmitters) do
		SetStaticEmitterEnabled(emitter.name, emitter.enabled)
	end
end

local function invalidateIdleCams()
	InvalidateIdleCam()
	InvalidateVehicleIdleCam()
end

exports("enableEntity", enableEntity)
exports("disableEntity", disableEntity)
exports("createMediaPlayer", createMediaPlayer)
exports("deleteMediaPlayer", deleteMediaPlayer)

RegisterNUICallback("startup", function(data, cb)
	loadSettings()

	TriggerServerEvent("pmms:loadPermissions")
	TriggerServerEvent("pmms:loadSettings")

	cb {
		enableFilterByDefault = false,
		defaultSameRoomAttenuation = MediaConfig.defaultSameRoomAttenuation,
		defaultDiffRoomAttenuation = MediaConfig.defaultDiffRoomAttenuation,
		defaultDiffRoomVolume = MediaConfig.defaultDiffRoomVolume,
		defaultRange = MediaConfig.defaultRange,
		maxRange = MediaConfig.maxRange,
		defaultScaleformName = MediaConfig.defaultScaleformName,
		defaultVideoSize = MediaConfig.defaultVideoSize,
		audioVisualizations = MediaConfig.audioVisualizations,
		tooltipsEnabled = tooltipsEnabled,
		currentServerEndpoint = GetCurrentServerEndpoint()
	}
end)

RegisterNUICallback("duiStartup", function(data, cb)
	cb {
		audioVisualizations = MediaConfig.audioVisualizations,
		currentServerEndpoint = GetCurrentServerEndpoint()
	}
end)

RegisterNUICallback("init", function(data, cb)
	-- Une télé de map n'est pas en réseau et le NUI n'envoie pas ses coords.
	-- Sans ça, pmms:init ne part jamais : le son joue dans l'UI, mais aucun
	-- lecteur n'est enregistré et la vidéo n'est jamais dessinée sur l'écran.
	if data.handle and doesEntityExist(data.handle) and not NetworkDoesNetworkIdExist(data.handle) then
		data.options.coords = GetEntityCoords(data.handle)
		data.options.model = GetEntityModel(data.handle)
		if data.options.model and data.options.model ~= 0 then
			local configured = MediaConfig.models[data.options.model] and MediaConfig.models[data.options.model].renderTarget
			data.options.renderTarget = resolveRenderTarget(data.options.model, configured or data.options.renderTarget)
		end
		data.handle = false
	end

	if NetworkDoesNetworkIdExist(data.handle) or data.options.coords then
		if data.options.coords then
			data.options.coords = ToVector3(data.options.coords)
		end

		if data.options.scaleform then
			data.options.scaleform.position = ToVector3(data.options.scaleform.position)
			data.options.scaleform.rotation = ToVector3(data.options.scaleform.rotation)
			data.options.scaleform.scale = ToVector3(data.options.scaleform.scale)
		end

		TriggerServerEvent("pmms:init", data.handle, data.options)
	end
	cb({})
end)

RegisterNUICallback("initError", function(data, cb)
	TriggerEvent("pmms:error", "Error loading " .. data.url .. ": " .. data.message)
	cb({})
end)

RegisterNUICallback("playError", function(data, cb)
	TriggerEvent("pmms:error", "Error playing " .. data.url .. ": " .. data.message)
	cb({})
end)

RegisterNUICallback("play", function(data, cb)
	if data.options.scaleform then
		data.options.scaleform.position = ToVector3(data.options.scaleform.position)
		data.options.scaleform.rotation = ToVector3(data.options.scaleform.rotation)
		data.options.scaleform.scale = ToVector3(data.options.scaleform.scale)

		if not data.handle or data.handle == -1 then
			data.handle = false
			data.options.coords = data.options.scaleform.position
			data.options.scaleform.standalone = true
		end
	end

	startMediaPlayer(data.handle, data.options)

	cb({})
end)

RegisterNUICallback("pause", function(data, cb)
	TriggerServerEvent("pmms:pause", data.handle)
	cb({})
end)

RegisterNUICallback("stop", function(data, cb)
	stopMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("closeUi", function(data, cb)
	SetNuiFocus(false, false)
	uiIsOpen = false
	-- L'interface du lecteur est une page a part, embarquee dans celle de la base :
	-- il faut lui dire de se retirer, sinon elle resterait affichee par-dessus le jeu.
	SendNUIMessage({ type = "hideUi" })
	cb({})
end)

RegisterNUICallback("seekBackward", function(data, cb)
	setMediaPlayerStartTime(data.handle, mediaPlayers[data.handle].startTime + 10)
	cb({})
end)

RegisterNUICallback("seekForward", function(data, cb)
	setMediaPlayerStartTime(data.handle, mediaPlayers[data.handle].startTime - 10)
	cb({})
end)

RegisterNUICallback("seekToTime", function(data, cb)
	local p = mediaPlayers[data.handle]
	setMediaPlayerStartTime(data.handle, p.startTime + (p.offset - data.offset))
	cb({})
end)

RegisterNUICallback("lock", function(data, cb)
	lockMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("unlock", function(data, cb)
	unlockMediaPlayer(data.handle)
	cb({})
end)

RegisterNUICallback("setBaseVolume", function(data, cb)
	setBaseVolume(data.volume)
	cb({})
end)

RegisterNUICallback("enableVideo", function(data, cb)
	enableVideo(data.handle)
	cb({})
end)

RegisterNUICallback("disableVideo", function(data, cb)
	disableVideo(data.handle)
	cb({})
end)

RegisterNUICallback("decreaseVideoSize", function(data, cb)
	TriggerServerEvent("pmms:setVideoSize", data.handle, mediaPlayers[data.handle].videoSize - 10)
	cb({})
end)

RegisterNUICallback("increaseVideoSize", function(data, cb)
	TriggerServerEvent("pmms:setVideoSize", data.handle, mediaPlayers[data.handle].videoSize + 10)
	cb({})
end)

RegisterNUICallback("mute", function(data, cb)
	TriggerServerEvent("pmms:mute", data.handle)
	cb({})
end)

RegisterNUICallback("unmute", function(data, cb)
	TriggerServerEvent("pmms:unmute", data.handle)
	cb({})
end)

RegisterNUICallback("copy", function(data, cb)
	copyMediaPlayer(data.oldHandle, data.newHandle)
	cb({})
end)

RegisterNUICallback("setLoop", function(data, cb)
	TriggerServerEvent("pmms:setLoop", data.handle, data.loop)
	cb({})
end)

RegisterNUICallback("next", function(data, cb)
	TriggerServerEvent("pmms:next", data.handle)
	cb({})
end)

RegisterNUICallback("removeFromQueue", function(data, cb)
	TriggerServerEvent("pmms:removeFromQueue", data.handle, data.index)
	cb({})
end)

RegisterNUICallback("toggleStatus", function(data, cb)
	TriggerEvent("pmms:toggleStatus")
	cb({})
end)

RegisterNUICallback("setMediaPlayerDefaults", function(data, cb)
	local handle
	local entity
	local coords

	if data.handle > 0 then
		if NetworkDoesNetworkIdExist(data.handle) then
			handle = data.handle
			entity = NetworkGetEntityFromNetworkId(data.handle)
			coords = GetEntityCoords(entity)
		elseif doesEntityExist(data.handle) then
			entity = data.handle
			coords = GetEntityCoords(entity)
			handle = GetHandleFromCoords(coords)
		end
	end

	if not handle then
		handle = data.handle
	end

	local defaults

	if entity and coords then
		defaults = GetDefaultMediaPlayer(MediaConfig.defaultMediaPlayers, coords) or MediaConfig.models[GetEntityModel(entity)]
	else
		for _, dmp in ipairs(MediaConfig.defaultMediaPlayers) do
			if GetHandleFromCoords(dmp.position) == handle then
				defaults = dmp
				break
			end
		end
	end

	local defaultsData = {}

	if defaults then
		for k, v in pairs(defaults) do
			defaultsData[k] = v
		end
	end

	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		defaultsData.label = mediaPlayers[handle].label
		defaultsData.volume = mediaPlayers[handle].volume
		defaultsData.attenuation = mediaPlayers[handle].attenuation
		defaultsData.diffRoomVolume = mediaPlayers[handle].diffRoomVolume
		defaultsData.range = mediaPlayers[handle].range
		defaultsData.isVehicle = mediaPlayers[handle].isVehicle
		defaultsData.scaleform = mediaPlayers[handle].scaleform
	end

	if not defaultsData.label and entity then
		defaultsData.label = getEntityLabel(handle, entity)
	end

	if defaultsData.isVehicle == nil and entity then
		defaultsData.isVehicle = IsEntityAVehicle(entity)
	end

	if defaultsData.scaleform then
		defaultsData.scaleform = json.encode(defaultsData.scaleform)
	end

	cb(defaultsData or {})
end)

RegisterNUICallback("save", function(data, cb)
	if data.scaleform then
		data.scaleform.position = ToVector3(data.scaleform.position)
		data.scaleform.rotation = ToVector3(data.scaleform.rotation)
		data.scaleform.scale = ToVector3(data.scaleform.scale)
	end

	if data.method == "new-model" then
		TriggerServerEvent("pmms:saveModel", GetHashKey(data.model), data)
	else
		local entity

		if NetworkDoesNetworkIdExist(data.handle) then
			entity = NetworkGetEntityFromNetworkId(data.handle)
		elseif doesEntityExist(data.handle) then
			entity = data.handle
		end

		if data.method == "client-model" or data.method == "server-model" then
			if entity then
				local model = GetEntityModel(entity)

				if data.method == "client-model" then
					print("Client-side model saving is not implemented yet")
				elseif data.method == "server-model" then
					TriggerServerEvent("pmms:saveModel", model, data)
				end
			end
		elseif data.method == "client-entity" or data.method == "server-entity" then
			local coords

			if entity then
				coords = GetEntityCoords(entity)
			elseif data.scaleform then
				coords = data.scaleform.position
			end

			if coords then
				if data.method == "client-entity" then
					print("Client-side entity saving is not implemented yet")
				elseif data.method == "server-entity" then
					TriggerServerEvent("pmms:saveEntity", coords, data)
				end
			end
		end
	end

	cb({})
end)

RegisterNUICallback("setVolume", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setVolume", handle, data.volume)
	end

	cb({})
end)

RegisterNUICallback("setAttenuation", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setAttenuation", handle, data.sameRoom, data.diffRoom)
	end

	cb({})
end)

RegisterNUICallback("setDiffRoomVolume", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setDiffRoomVolume", handle, data.diffRoomVolume)
	end

	cb({})
end)

RegisterNUICallback("setRange", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setRange", handle, data.range)
	end

	cb({})
end)

RegisterNUICallback("setIsVehicle", function(data, cb)
	local handle = getSvHandle(data.handle)

	if handle and mediaPlayers[handle] then
		TriggerServerEvent("pmms:setIsVehicle", handle, data.isVehicle)
	end

	cb({})
end)

RegisterNUICallback("setScaleform", function(data, cb)
	local handle = getSvHandle(data.handle)

	local response = {}

	if handle and mediaPlayers[handle] then
		data.scaleform.position = ToVector3(data.scaleform.position)
		data.scaleform.rotation = ToVector3(data.scaleform.rotation)
		data.scaleform.scale = ToVector3(data.scaleform.scale)

		if mediaPlayers[handle].scaleform and data.scaleform.attached ~= mediaPlayers[handle].scaleform.attached then
			if data.scaleform.attached then
				data.scaleform.position = vector3(0, 0, 0)
				data.scaleform.rotation = vector3(0, 0, 0)
			elseif mediaPlayers[handle].scaleform.attached then
				data.scaleform.position = mediaPlayers[handle].scaleform.finalPosition
				data.scaleform.rotation = mediaPlayers[handle].scaleform.finalRotation
			end

			response.scaleform = {
				position = {
					x = data.scaleform.position.x,
					y = data.scaleform.position.y,
					z = data.scaleform.position.z
				},
				rotation = {
					x = data.scaleform.rotation.x,
					y = data.scaleform.rotation.y,
					z = data.scaleform.rotation.z
				}
			}
		end

		TriggerServerEvent("pmms:setScaleform", handle, data.scaleform)

		mediaPlayers[handle].scaleform = data.scaleform
	end

	cb(response)
end)

RegisterNUICallback("delete", function(data, cb)
	local model, coords

	if NetworkDoesNetworkIdExist(data.handle) then
		local entity = NetworkGetEntityFromNetworkId(data.handle)
		model = GetEntityModel(entity)
		coords = GetEntityCoords(entity)
	elseif doesEntityExist(data.handle) then
		coords = GetEntityCoords(data.handle)
	elseif data.coords then
		coords = ToVector3(data.coords)
	end

	if data.method == "server-model" and model then
		TriggerServerEvent("pmms:deleteModel", model)
	elseif data.method == "server-entity" and coords then
		TriggerServerEvent("pmms:deleteEntity", coords)
	end

	cb({})
end)

RegisterNUICallback("getScaleformSettingsFromMyPosition", function(data, cb)
	local ped = PlayerPedId()

	local pos = GetEntityCoords(ped)
	local rot = GetEntityRotation(ped)

	cb(json.encode({
		position = pos,
		rotation = rot
	}))
end)

RegisterNUICallback("getScaleformSettingsFromEntity", function(data, cb)
	local entity

	if NetworkDoesNetworkIdExist(data.handle) then
		entity = NetworkGetEntityFromNetworkId(data.handle)
	else
		entity = data.handle
	end

	local pos = GetEntityCoords(entity)
	local rot = GetEntityRotation(entity)

	cb(json.encode({
		position = pos,
		rotation = rot
	}))
end)

RegisterNUICallback("fix", function(data, cb)
	TriggerEvent("pmms:reset")

	cb {}
end)

RegisterNUICallback("toggleTips", function(data, cb)
	tooltipsEnabled = data.enabled

	SetResourceKvp("tooltipsEnabled", tooltipsEnabled and "yes" or "no")

	cb {}
end)

RegisterNUICallback("notify", function(data, cb)
	notify {
		title = data.title,
		text = data.text,
		duration = data.duration
	}

	cb {}
end)

AddEventHandler("pmms:sync", function(players)
	if syncIsEnabled then
		mediaPlayers = players

		if uiIsOpen or statusIsShown then
			updateUi()
		end
	end
end)

AddEventHandler("pmms:start", function(handle, options)
	sendMediaMessage(handle, options.coords, {
		type = "init",
		handle = handle,
		options = options
	})
end)

AddEventHandler("pmms:play", function(handle)
	sendMediaMessage(handle, nil, {
		type = "play",
		handle = handle
	})
end)

AddEventHandler("pmms:stop", function(handle)
	local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

	if duiBrowser then
		duiBrowser:delete()
	else
		SendNUIMessage({
			type = "stop",
			handle = handle
		})
	end
end)

AddEventHandler("pmms:showControls", function(preferredEntity)
	-- Les droits partaient seulement du callback NUI `startup`. Dans une
	-- iframe, ce callback peut rater : interact restait à false et la liste
	-- des véhicules (la flèche) restait vide et désactivée.
	TriggerServerEvent("pmms:loadPermissions")
	TriggerServerEvent("pmms:loadSettings")

	-- Droits optimistes le temps de la réponse serveur : sinon le premier
	-- updateUi désactive le menu déroulant et le clic sur la flèche ne fait rien.
	permissions.interact = true
	permissions.anyEntity = true
	if permissions.customUrl == nil then
		permissions.customUrl = true
	end

	local preferredHandle = nil
	if preferredEntity and doesEntityExist(preferredEntity) then
		-- Télé / objet du menu contextuel : forcer sa présence dans la liste
		-- et l'annoncer à l'UI pour pré-sélection.
		enableEntity(preferredEntity)
		local model = GetEntityModel(preferredEntity)
		if model and MediaConfig.models and not MediaConfig.models[model] then
			MediaConfig.models[model] = {
				label = "TV",
				renderTarget = "tvscreen",
			}
		end
		preferredHandle = getHandle(preferredEntity)
	end

	SendNUIMessage({
		type = "showUi",
		preferredHandle = preferredHandle
	})
	SetNuiFocus(true, true)
	uiIsOpen = true
	-- Remplir tout de suite la liste des lecteurs proches : sans cela, elle
	-- n'apparaissait qu'au prochain sync serveur (~500 ms), voire jamais si
	-- les permissions n'étaient pas encore arrivées.
	updateUi()

	if preferredHandle then
		SendNUIMessage({
			type = "selectMediaPlayer",
			handle = preferredHandle
		})
	end
end)

AddEventHandler("pmms:toggleStatus", function()
	toggleStatus()

	if MediaConfig.showNotifications then
		notify{text = "Status " .. (statusIsShown and "enabled" or "disabled"), duration = 1000}
	end
end)

AddEventHandler("pmms:error", function(message)
	print(message)

	if MediaConfig.showNotifications then
		notify{text = message}
	end
end)

AddEventHandler("pmms:init", function(handle, options)
	startMediaPlayer(handle, options)
end)

AddEventHandler("pmms:reset", function()
	if MediaConfig.showNotifications then
		notify{text = "Réinitialisation..."}
	end

	syncIsEnabled = false

	SendNUIMessage({
		type = "reset"
	})

	mediaPlayers = {}
	localMediaPlayers = {}

	DuiBrowser:resetPool()

	syncIsEnabled = true
end)

AddEventHandler("pmms:startClosestMediaPlayer", function(options)
	startClosestMediaPlayer(options)
end)

AddEventHandler("pmms:pauseClosestMediaPlayer", function()
	pauseClosestMediaPlayer()
end)

AddEventHandler("pmms:stopClosestMediaPlayer", function()
	stopClosestMediaPlayer()
end)

AddEventHandler("pmms:listPresets", function()
	listPresets()
end)

AddEventHandler("pmms:showBaseVolume", function()
	notify{text = "Volume: " .. baseVolume}
end)

AddEventHandler("pmms:setBaseVolume", function(volume)
	setBaseVolume(volume)
end)

AddEventHandler("pmms:loadPermissions", function(perms)
	permissions = perms
	-- Une ouverture d'interface peut arriver avant la réponse serveur : on
	-- rafraîchit la liste (véhicules / objets proches) dès que les droits
	-- sont connus, sinon le menu déroulant reste vide.
	if uiIsOpen or statusIsShown then
		updateUi()
	end
end)

AddEventHandler("pmms:loadSettings", function(models, defaultMediaPlayers)
	MediaConfig.models = models

	-- Keep local entity handles of default media players
	for _, dmp1 in ipairs(MediaConfig.defaultMediaPlayers) do
		if dmp1.handle then
			local dmp2 = GetDefaultMediaPlayer(defaultMediaPlayers, dmp1.position)

			if dmp2 then
				dmp2.handle = dmp1.handle
			end
		end
	end

	MediaConfig.defaultMediaPlayers = defaultMediaPlayers
end)

AddEventHandler("pmms:notify", function(data)
	notify(data)
end)

AddEventHandler("pmms:enableEntity", enableEntity)
AddEventHandler("pmms:disableEntity", disableEntity)

AddEventHandler("pmms:refreshPermissions", function()
	TriggerServerEvent("pmms:loadPermissions")
end)

Citizen.CreateThread(function()
	-- Ne pas attendre le premier `startup` NUI : dans l'iframe, il peut échouer
	-- et laisser interact à false (menu des véhicules inutilisable).
	TriggerServerEvent("pmms:loadPermissions")
	TriggerServerEvent("pmms:loadSettings")
end)

AddEventHandler("onResourceStop", function(resource)
	if GetCurrentResourceName() ~= resource then
		return
	end

	for _, mediaPlayer in ipairs(MediaConfig.defaultMediaPlayers) do
		if mediaPlayer.handle then
			DeleteEntity(mediaPlayer.handle)
		end
	end

	for entity, _ in pairs(personalMediaPlayers) do
		DeleteEntity(entity)
	end

	if uiIsOpen then
		SetNuiFocus(false, false)
	end
end)

Citizen.CreateThread(function()
	if MediaConfig.autoDisableStaticEmitters then
		restoreStaticEmitters()
	end
end)

Citizen.CreateThread(function()
	while true do
		local ped, listenPos, viewerPos, viewerFov = getListenerAndViewerInfo()

		local canWait = true
		local duiToDraw = {}

		for handle, info in pairs(mediaPlayers) do
			local entity

			if info.coords then
				info.coords = asVector3(info.coords) or info.coords
				entity = getLocalMediaPlayer(info.coords, listenPos, info.range or MediaConfig.maxRange)
			elseif NetworkDoesNetworkIdExist(handle) then
				entity = NetworkGetEntityFromNetworkId(handle)
			elseif doesEntityExist(handle) then
				entity = handle
			end

			local data

			local entityExists = doesEntityExist(entity)

			local mediaPos

			if entityExists then
				mediaPos = GetEntityCoords(entity)
			elseif info.coords then
				mediaPos = info.coords
			end

			if mediaPos then
				local distance = #(listenPos - mediaPos)

				local camDistance
				local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(mediaPos.x, mediaPos.y, mediaPos.z + 0.8)

				if onScreen and not isPauseMenuOrMapActive() then
					camDistance = #(viewerPos - mediaPos)
				else
					camDistance = -1
				end

				local sameRoom

				if entityExists then
					if info.isVehicle then
						sameRoom = IsPedInVehicle(ped, entity, false)
					else
						sameRoom = isInSameRoom(ped, entity)
					end
				elseif info.scaleform and info.scaleform.standalone then
					sameRoom = true
				else
					sameRoom = false
				end

				if info.scaleform and info.scaleform.attached then
					if entityExists and NetworkGetEntityIsNetworked(entity) then
						local mediaRot = GetEntityRotation(entity, 0)

						local r = math.rad(mediaRot.z)
						local cosr = math.cos(r)
						local sinr = math.sin(r)

						local posX = (info.scaleform.position.x * cosr - info.scaleform.position.y * sinr) + mediaPos.x
						local posY = (info.scaleform.position.y * cosr + info.scaleform.position.x * sinr) + mediaPos.y
						local posZ = info.scaleform.position.z + mediaPos.z

						info.scaleform.finalPosition = vector3(posX, posY, posZ)

						-- FIXME: This really only works for the Z rotation (yaw)
						info.scaleform.finalRotation = -(mediaRot + info.scaleform.rotation)
					elseif info.scaleform.finalPosition and info.scaleform.finalRotation then
						info.scaleform.finalPosition = nil
						info.scaleform.finalRotation = nil
					end
				end

				data = {
					type = "update",
					handle = handle,
					options = info,
					volume = math.floor(info.volume * (baseVolume / 100)),
					distance = distance,
					sameRoom = sameRoom,
					camDistance = camDistance,
					fov = viewerFov,
					screenX = screenX,
					screenY = screenY
				}

				if distance < info.range then
					canWait = false
				end

				local duiBrowser = DuiBrowser:getBrowserForHandle(handle)

				if duiBrowser and duiBrowser:isDrawable() then
					local name = duiBrowser:getDrawableName()

					if distance < info.range then
						if not duiToDraw[name] then
							duiToDraw[name] = {}
						end

						table.insert(duiToDraw[name], {
							duiBrowser = duiBrowser,
							distance = distance
						})
					end
				end
			else
				data = {
					type = "update",
					handle = handle,
					options = info,
					volume = 0,
					distance = -1,
					sameRoom = false,
					camDistance = -1,
					fov = viewerFov,
					screenX = 0,
					screenY = 0
				}
			end

			sendMediaMessage(handle, info.coords, data)
		end

		for _, items in pairs(duiToDraw) do
			table.sort(items, function(a, b)
				return a.distance < b.distance
			end)

			for i = 2, #items do
				items[i].duiBrowser:disable()
			end

			items[1].duiBrowser:draw()
		end

		if canWait then
			if MediaConfig.autoDisableStaticEmitters and staticEmittersDisabled then
				restoreStaticEmitters()
				staticEmittersDisabled = false
			end

			if disableIdleCam then
				disableIdleCam = false
			end

			Citizen.Wait(1000)
		else
			if MediaConfig.autoDisableStaticEmitters and not staticEmittersDisabled then
				disableStaticEmitters()
				staticEmittersDisabled = true
			end

			if MediaConfig.autoDisableIdleCam and not disableIdleCam then
				invalidateIdleCams()
				disableIdleCam = true
			end

			Citizen.Wait(0)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		local myPos = GetEntityCoords(PlayerPedId())

		for handle, info in pairs(mediaPlayers) do
			if info.coords and not (info.scaleform and info.scaleform.standalone) then
				getLocalMediaPlayer(info.coords, myPos, info.range)
			end

			if not MediaConfig.autoDisableVehicleRadio then
				local entity

				if info.coords then
					entity = localMediaPlayers[handle]
				elseif NetworkDoesNetworkIdExist(handle) then
					entity = NetworkGetEntityFromNetworkId(handle)
				end

				if doesEntityExist(entity) and IsEntityAVehicle(entity) then
					SetVehRadioStation(entity, "OFF")
				end
			end
		end

		for _, mediaPlayer in ipairs(MediaConfig.defaultMediaPlayers) do
			if mediaPlayer.spawn then
				local nearby = #(myPos - mediaPlayer.position) <= MediaConfig.defaultMediaPlayerSpawnDistance

				if mediaPlayer.handle and not doesEntityExist(mediaPlayer.handle) then
					mediaPlayer.handle = nil
				end

				if nearby and not mediaPlayer.handle then
					createDefaultMediaPlayer(mediaPlayer)
				elseif not nearby and mediaPlayer.handle then
					DeleteEntity(mediaPlayer.handle)
				end
			end
		end

		Citizen.Wait(1000)
	end
end)

Citizen.CreateThread(function()
	while true do
		if disableIdleCam then
			invalidateIdleCams()
		end

		Citizen.Wait(10000)
	end
end)
