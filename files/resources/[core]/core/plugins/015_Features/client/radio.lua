---@meta _
---@diagnostic disable: duplicate-doc-field

local Radio = {
    Has = true,
    Open = false,
    frequence = 80.8,
    On = false,
    opening = false,
    Enabled = true,
    Handle = nil,
    Prop = joaat('prop_cs_hand_radio'),
    Bone = 28422,
    Offset = vector3(0.0, 0.0, 0.0),
    Rotation = vector3(0.0, 0.0, 0.0),
    Dictionary = {
        "cellphone@",
        "cellphone@in_car@ds",
        "cellphone@str",
        "random@arrests",
    },
    Animation = {
        "cellphone_text_in",
        "cellphone_text_out",
        "cellphone_call_listen_a",
        "generic_radio_chatter",
    },
    Clicks = true,
    AllowRadioWhenClosed = true,
    volume = 50,
}

local loaded = true

--- IsFrequencyValid
---@param freq any
---@return boolean
local function IsFrequencyValid(freq)
    if freq < 0.0 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas mettre une fréquence négative."
        })
        return false
    elseif freq > 1000.0 then
        VFW.ShowNotification({
            type = 'ROUGE',
            content = "Vous ne pouvez pas mettre une fréquence supérieure à 1000."
        })
        return false
    end

    return true
end

--- RadioToggle
---@param toggle any
local function RadioToggle(toggle)
    local playerPed = VFW.PlayerData.ped

    if not Radio.Has or IsEntityDead(playerPed) then
        Radio.Open = false
        if Radio.Handle then
            DetachEntity(Radio.Handle, true, false)
            DeleteEntity(Radio.Handle)
        end

        return
    end

    if Radio.Open == toggle then
        return
    end

    Radio.Open = toggle

    if Radio.On and not Radio.AllowRadioWhenClosed then
        exports["pma-voice"]:setVoiceProperty("radioEnabled", toggle)
    end

    local dictionaryType = 1 + (IsPedInAnyVehicle(playerPed, false) and 1 or 0)
    local animationType = 1 + (Radio.Open and 0 or 1)
    local dictionary = Radio.Dictionary[dictionaryType]
    local animation = Radio.Animation[animationType]

    RequestAnimDict(dictionary)
    while not HasAnimDictLoaded(dictionary) do
        loaded = false
        Wait(150)
    end

    if Radio.Open then
        RequestModel(Radio.Prop)
        while not HasModelLoaded(Radio.Prop) do
            loaded = false
            Wait(150)
        end

        loaded = true
        Radio.Handle = CreateObject(Radio.Prop, 0.0, 0.0, 0.0, false, true, false)

        local bone = GetPedBoneIndex(playerPed, Radio.Bone)
        SetEntityAsMissionEntity(Radio.Handle, true, true)
        SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
        SetEntityCollision(Radio.Handle, false, false)
        AttachEntityToEntity(Radio.Handle, playerPed, bone, Radio.Offset.x, Radio.Offset.y, Radio.Offset.z,
                Radio.Rotation.x, Radio.Rotation.y, Radio.Rotation.z, true, false, false, false, 2, true)
        if NetworkGetEntityIsNetworked(Radio.Handle) then
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(Radio.Handle), true)
        end

        SetModelAsNoLongerNeeded(Radio.Prop)
        TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)
    else
        loaded = false
        TaskPlayAnim(playerPed, dictionary, animation, 4.0, -1, -1, 50, 0, false, false, false)
        Wait(700)
        StopAnimTask(playerPed, dictionary, animation, 1.0)

        if Radio.Handle then
            local count = 0
            NetworkRequestControlOfEntity(Radio.Handle)
            while not NetworkHasControlOfEntity(Radio.Handle) and count < 1000 do
                Wait(0)
                count = count + 1
            end

            DetachEntity(Radio.Handle, true, false)
            DeleteEntity(Radio.Handle)
        end

        loaded = true
    end
end

--- OpenRadio
local function OpenRadio()
    RadioToggle(true)

    VFW.Nui.Radio(true,  {
        frequence = math.round(Radio.frequence, 1)
    })

    Radio.opening = false

    CreateThread(function()
        local disabledControls = {
            24, 25, 1, 2, 142, 18, 322, 106, 263, 264, 257, 140, 141, 142, 143
        }

        while Radio.Open do
            for _, control in ipairs(disabledControls) do
                DisableControlAction(0, control, Radio.On)
            end

            Wait(0)
        end
    end)
end

RegisterNUICallback("radio__callback", function(data, cb)
    if data.action == "soundup" then
        Radio.volume = math.min(Radio.volume + 5, 100)
        exports["pma-voice"]:setRadioVolume(Radio.volume)
    elseif data.action == "sounddown" then
        Radio.volume = math.max(Radio.volume - 5, 0)
        exports["pma-voice"]:setRadioVolume(Radio.volume)
    elseif data.args == "remove" then
        local newFreq = Radio.frequence + 0.1
        
        if IsFrequencyValid(newFreq) then
            Radio.frequence = newFreq
            VFW.Nui.Radio(true,  {
                frequence = math.round(Radio.frequence, 1)
            })
        end
    elseif data.args == "add" then
        local newFreq = Radio.frequence - 0.1
        
        if IsFrequencyValid(newFreq) then
            Radio.frequence = newFreq
            VFW.Nui.Radio(true,  {
                frequence = math.round(Radio.frequence, 1)
            })
        end
    elseif data.action == "toggle" then
        Radio.On = not Radio.On
        exports["pma-voice"]:setVoiceProperty("radioEnabled", Radio.On)
        cb(Radio.On)
    elseif data.action == "man" then
        local freq = tonumber(VFW.Nui.KeyboardInput(true, "Fréquence"))

        if freq and type(freq) == "number" and IsFrequencyValid(freq) then
            Radio.frequence = freq
            VFW.Nui.Radio(true,  {
                frequence = math.round(Radio.frequence, 1)
            })
        elseif not freq then
            VFW.ShowNotification({
                type = 'ROUGE',
                content = "Vous n'avez pas rentré un nombre"
            })
        end
    end

    exports["pma-voice"]:setRadioChannel(Radio.On and math.round(Radio.frequence, 1) or 0)
end)

local hasRadio = false

--RegisterKeyMapping("+radio", "Ouvrir la radio", "keyboard", "P")
--RegisterCommand("+radio", function()
--    for i = 1, #VFW.PlayerData.inventory do
--        if VFW.PlayerData.inventory[i].name == "radio" then
--            hasRadio = true
--            break
--        end
--    end
--
--    if not hasRadio then
--        VFW.ShowNotification({
--            type = 'ROUGE',
--            content = "Vous n'avez pas de radio"
--        })
--        return
--    end
--
--    if not loaded then
--        return
--    end
--
--    if not Radio.Open then
--        Radio.volume = 50
--        exports["pma-voice"]:setRadioVolume(50)
--        OpenRadio()
--    else
--        RadioToggle(false)
--        VFW.Nui.Radio(false)
--    end
--end)
