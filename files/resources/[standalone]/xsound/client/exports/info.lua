soundInfo = {}

function getLink(name_)
    return soundInfo[name_].url
end

exports('getLink', getLink)

function getPosition(name_)
    return soundInfo[name_].position
end

exports('getPosition', getPosition)

function isLooped(name_)
    return soundInfo[name_].loop
end

exports('isLooped', isLooped)

function getInfo(name_)
    return soundInfo[name_]
end

exports('getInfo', getInfo)

function soundExists(name_)
    if soundInfo[name_] == nil then
        return false
    end
    return true
end

exports('soundExists', soundExists)

function isPlaying(name_)
    return soundInfo[name_].playing
end

exports('isPlaying', isPlaying)

function isPaused(name_)
    return soundInfo[name_].paused
end

exports('isPaused', isPaused)

function getDistance(name_)
    return soundInfo[name_].distance
end

exports('getDistance', getDistance)

function getVolume(name_)
    return soundInfo[name_].volume
end

exports('getVolume', getVolume)

function isDynamic(name_)
    return soundInfo[name_].isDynamic
end

exports('isDynamic', isDynamic)

function getTimeStamp(name_)
    return soundInfo[name_].timeStamp or -1
end

exports('getTimeStamp', getTimeStamp)

--- Demande le timestamp actuel au player JS et attend la réponse
--- @param name_ string ID du son
--- @return number Timestamp actuel en secondes
function getCurrentTime(name_)
    if not soundInfo[name_] then
        return 0
    end

    -- Envoyer la demande au JS
    SendNUIMessage({
        status = "getCurrentTime",
        name = name_
    })

    -- Attendre un court instant pour que le JS réponde
    Wait(50)

    -- Retourner la valeur mise à jour
    return soundInfo[name_].timeStamp or 0
end

exports('getCurrentTime', getCurrentTime)

function getMaxDuration(name_)
    return soundInfo[name_].maxDuration or -1
end

exports('getMaxDuration', getMaxDuration)

function isPlayerInStreamerMode()
    return disableMusic
end

exports('isPlayerInStreamerMode', isPlayerInStreamerMode)

function getAllAudioInfo()
    return soundInfo
end

exports('getAllAudioInfo', getAllAudioInfo)

function isPlayerCloseToAnySound()
    return isPlayerCloseToMusic
end

exports('isPlayerCloseToAnySound', isPlayerCloseToAnySound)