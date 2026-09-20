if MENTA_SERVER ~= 'FR' then return end

Showed = false

function NuiShow(state)
    Showed = state

    SendNUIMessage({
        type = "visible",
        data = state
    })
end

function NuiSound()
    SendNUIMessage({
        type = "clickSound"
    })
end

function NuiSiren(state)
    SendNUIMessage({
        type = "siren",
        data = state
    })
end

function NuiFlashingLight(state)
    SendNUIMessage({
        type = "flashingLight",
        data = state
    })
end

function NuiLightHouse(state)
    SendNUIMessage({
        type = "lightHouse",
        data = state
    })
end

function NuiNightSiren(state)
    SendNUIMessage({
        type = "nightSiren",
        data = state
    })
end

function NuiBanisterLeft(state)
    SendNUIMessage({
        type = "banisterLeft",
        data = state
    })
end

function NuiBanisterCenter(state)
    SendNUIMessage({
        type = "banisterCenter",
        data = state
    })
end

function NuiBanisterRight(state)
    SendNUIMessage({
        type = "banisterRight",
        data = state
    })
end

function NuiLight(state)
    SendNUIMessage({
        type = "projector",
        data = state
    })
end
