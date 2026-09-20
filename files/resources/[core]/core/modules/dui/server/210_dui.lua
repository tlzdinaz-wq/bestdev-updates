VFW.DUI = VFW.DUI or {}

local presets = {}

local DEFAULT_PRESET = {
    key = "E",
    label = "Interagir",
    icons = "default",
    keyColor = "#FFFFFF",
    labelGradientStart = "#FFFFFF",
    labelGradientEnd = "#CACACA",
    labelOpacity = 1.0,
    innerGradientStart = "#D9D9D9",
    innerGradientEnd = "#EFEFEF",
    outerStrokeStart = "#FFFFFF",
    outerStrokeEnd = "#CACACA",
    glowColor = "#FFFFFF",
}

function VFW.DUI.GetPageUrl()
    return ("nui://cfx-nui-%s/modules/dui/index.html"):format(GetCurrentResourceName())
end

function VFW.DUI.GetIconUrl(icon)
    if type(icon) ~= "string" or icon == "" then icon = DEFAULT_PRESET.icons end
    return VFW.CdnUrl(("interacts/%s.svg"):format(icon))
end

function VFW.DUI.GetDefaultPreset()
    return VFW.DeepCopy and VFW.DeepCopy(DEFAULT_PRESET) or DEFAULT_PRESET
end

function VFW.DUI.RegisterPreset(name, data)
    if type(name) ~= "string" or name == "" then return false end
    if type(data) ~= "table" then return false end

    local preset = {}

    for key, value in pairs(DEFAULT_PRESET) do
        preset[key] = value
    end

    for key, value in pairs(data) do
        if type(key) == "string" and (type(value) == "string" or type(value) == "number" or type(value) == "boolean") then
            preset[key] = value
        end
    end

    presets[name] = preset

    return true
end

function VFW.DUI.GetPreset(name)
    if type(name) ~= "string" then return nil end
    return presets[name]
end

function VFW.DUI.GetPresets()
    return presets
end

exports("getDuiIconUrl", function(icon)
    return VFW.DUI.GetIconUrl(icon)
end)

exports("getDuiPreset", function(name)
    return VFW.DUI.GetPreset(name)
end)
