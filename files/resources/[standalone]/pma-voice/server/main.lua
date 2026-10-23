voiceData = {}
radioData = {}
callData = {}

-- Each player must transmit on their own Mumble channel. Clients then add the
-- channels of nearby players to their voice target. The client-side proximity
-- code relies on this replicated state being present before it can build that
-- target, so keep the allocation on the server and release it on disconnect.
local mappedChannels = {}

local function firstFreeChannel()
	for channel = 1, 2048 do
		if not mappedChannels[channel] then
			return channel
		end
	end

	return 0
end

function defaultTable(source)
	handleStateBagInitilization(source)
	return {
		radio = 0,
		call = 0,
		lastRadio = 0,
		lastCall = 0
	}
end

function handleStateBagInitilization(source)
	local plyState = Player(source).state
	if not plyState.pmaVoiceInit then 
		plyState:set('radio', GetConvarInt('voice_defaultRadioVolume', 30), true)
		plyState:set('phone', GetConvarInt('voice_defaultPhoneVolume', 60), true)
		plyState:set('proximity', {}, true)
		plyState:set('callChannel', 0, true)
		plyState:set('radioChannel', 0, true)
		plyState:set('voiceIntent', 'speech', true)
		-- We want to save voice inits because we'll automatically reinitalize calls and channels
		plyState:set('pmaVoiceInit', true, false)
	end

	local assignedChannel = firstFreeChannel()
	plyState:set('assignedChannel', assignedChannel, true)

	if assignedChannel ~= 0 then
		mappedChannels[assignedChannel] = source
		logger.verbose('[proximity] Assigned player %s to Mumble channel %s', source, assignedChannel)
	else
		logger.error('[proximity] Failed to find a free Mumble channel for player %s', source)
	end
end

Citizen.CreateThread(function()

	local plyTbl = GetPlayers()
	for i = 1, #plyTbl do
		local ply = tonumber(plyTbl[i])
		voiceData[ply] = defaultTable(plyTbl[i])
	end

	Wait(5000)

	local nativeAudio = GetConvar('voice_useNativeAudio', 'false')
	local _3dAudio = GetConvar('voice_use3dAudio', 'false')
	local _2dAudio = GetConvar('voice_use2dAudio', 'false')
	local sendingRangeOnly = GetConvar('voice_useSendingRangeOnly', 'false')
	local gameVersion = GetConvar('gamename', 'fivem')

	-- handle no convars being set (default drag n' drop)
	if
		nativeAudio == 'false'
		and _3dAudio == 'false'
		and _2dAudio == 'false'
	then
		if gameVersion == 'fivem' then
			SetConvarReplicated('voice_useNativeAudio', 'true')
			if sendingRangeOnly == 'false' then
				SetConvarReplicated('voice_useSendingRangeOnly', 'true')
			end
			logger.info('No convars detected for voice mode, defaulting to \'setr voice_useNativeAudio true\' and \'setr voice_useSendingRangeOnly true\'')
		else
			SetConvarReplicated('voice_use3dAudio', 'true')
			if sendingRangeOnly == 'false' then
				SetConvarReplicated('voice_useSendingRangeOnly', 'true')
			end
			logger.info('No convars detected for voice mode, defaulting to \'setr voice_use3dAudio true\' and \'setr voice_useSendingRangeOnly true\'')
		end
	elseif sendingRangeOnly == 'false' then
		logger.warn('It\'s recommended to have \'voice_useSendingRangeOnly\' set to true you can do that with \'setr voice_useSendingRangeOnly true\', this prevents players who directly join the mumble server from broadcasting to players.')
	end

	if GetConvar('gamename', 'fivem') == 'rdr3' then
		if nativeAudio == 'true' then
			logger.warn("RedM doesn't currently support native audio, automatically switching to 3d audio. This also means that submixes will not work.")
			SetConvarReplicated('voice_useNativeAudio', 'false')
			SetConvarReplicated('voice_use3dAudio', 'true')
		end
	end

	local radioVolume = GetConvarInt("voice_defaultRadioVolume", 30)
	local phoneVolume = GetConvarInt("voice_defaultPhoneVolume", 60)

	-- When casted to an integer these get set to 0 or 1, so warn on these values that they don't work
	if
		radioVolume == 0 or radioVolume == 1 or
		phoneVolume == 0 or phoneVolume == 1
	then
		SetConvarReplicated("voice_defaultRadioVolume", 30)
		SetConvarReplicated("voice_defaultPhoneVolume", 60)
		for i = 1, 5 do
			Wait(5000)
			logger.warn("`voice_defaultRadioVolume` or `voice_defaultPhoneVolume` have their value set as a float, this is going to automatically be fixed but please update your convars.")
		end
	end
end)

AddEventHandler('playerJoining', function()
	if not voiceData[source] then
		voiceData[source] = defaultTable(source)
	end
end)

AddEventHandler("playerDropped", function()
	local source = source
	local assignedChannel = Player(source).state.assignedChannel
	if voiceData[source] then
		local plyData = voiceData[source]

		if plyData.radio ~= 0 then
			removePlayerFromRadio(source, plyData.radio)
		end

		if plyData.call ~= 0 then
			removePlayerFromCall(source, plyData.call)
		end

		voiceData[source] = nil
	end

	if assignedChannel then
		mappedChannels[assignedChannel] = nil
		logger.verbose('[proximity] Released Mumble channel %s from player %s', assignedChannel, source)
	end
end)

if GetConvarInt('voice_externalDisallowJoin', 0) == 1 then
	AddEventHandler('playerConnecting', function(_, _, deferral)
		deferral.defer()
		Wait(0)
		deferral.done('This server is not accepting connections.')
	end)
end

-- only meant for internal use so no documentation
function isValidPlayer(source)
	return voiceData[source]
end
exports('isValidPlayer', isValidPlayer)

function getPlayersInRadioChannel(channel)
	local returnChannel = radioData[channel]
	if returnChannel then
		return returnChannel
	end
	-- channel doesnt exist
	return {}
end
exports('getPlayersInRadioChannel', getPlayersInRadioChannel)
exports('GetPlayersInRadioChannel', getPlayersInRadioChannel)
