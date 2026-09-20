local DISABLE_CONTROLS = {
    21, 22, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 45, 47, 56, 75,
    140, 141, 142, 143, 257, 263, 264
}

function DisableJobMovementControls()
    for i = 1, #DISABLE_CONTROLS do
        DisableControlAction(0, DISABLE_CONTROLS[i], true)
    end
end
