---@meta _
---@diagnostic disable: duplicate-doc-field

local IPLManager = {}
local LoadedIPLs = {}

local IPLData = {
    -- Appartements Luxe (High-End)
    ['apa_v_mp_h_01_a'] = {
        name = "Appartement Luxe 1",
        category = "Appartements",
        ipl = "apa_v_mp_h_01_a",
        props = { "apa_v_mp_h_01_a" }
    },
    ['apa_v_mp_h_01_b'] = {
        name = "Appartement Luxe 2",
        category = "Appartements",
        ipl = "apa_v_mp_h_01_b",
        props = { "apa_v_mp_h_01_b" }
    },
    ['apa_v_mp_h_01_c'] = {
        name = "Appartement Luxe 3",
        category = "Appartements",
        ipl = "apa_v_mp_h_01_c",
        props = { "apa_v_mp_h_01_c" }
    },
    -- Appartements Moyens (Mid-End)
    ['apa_v_mp_h_02_a'] = {
        name = "Appartement Moyen 1",
        category = "Appartements",
        ipl = "apa_v_mp_h_02_a",
        props = { "apa_v_mp_h_02_a" }
    },
    ['apa_v_mp_h_02_b'] = {
        name = "Appartement Moyen 2",
        category = "Appartements",
        ipl = "apa_v_mp_h_02_b",
        props = { "apa_v_mp_h_02_b" }
    },
    ['apa_v_mp_h_02_c'] = {
        name = "Appartement Moyen 3",
        category = "Appartements",
        ipl = "apa_v_mp_h_02_c",
        props = { "apa_v_mp_h_02_c" }
    },
    -- Appartements Low-End (intégrés au jeu)
    ['_lowend_apt'] = {
        name = "Appartement Low-Cost",
        category = "Appartements",
        ipl = nil, -- Pas d'IPL requis, intégré au jeu
        props = {}
    },
    -- Maisons
    ['lf_house_01'] = {
        name = "Maison 1",
        category = "Maisons",
        ipl = "lf_house_01",
        props = { "lf_house_01" }
    },
    ['lf_house_02'] = {
        name = "Maison 2",
        category = "Maisons",
        ipl = "lf_house_02",
        props = { "lf_house_02" }
    }
}

function IPLManager.LoadIPL(iplName)
    local iplData = IPLData[iplName]

    if not iplData then
        return false
    end

    if LoadedIPLs[iplName] then
        return true
    end

    -- Si pas d'IPL requis (intérieur intégré au jeu), marquer comme chargé
    if not iplData.ipl then
        LoadedIPLs[iplName] = true
        return true
    end

    RequestIpl(iplData.ipl)

    if iplData.props and #iplData.props > 0 then
        for _, prop in ipairs(iplData.props) do
            if prop ~= iplData.ipl then
                RequestIpl(prop)
            end
        end
    end

    local timeout = 0
    while not IsIplActive(iplData.ipl) and timeout < 100 do
        Wait(50)
        timeout = timeout + 1
    end

    if IsIplActive(iplData.ipl) then
        LoadedIPLs[iplName] = true
        return true
    else
        return false
    end
end

function IPLManager.UnloadIPL(iplName)
    local iplData = IPLData[iplName]

    if not iplData or not LoadedIPLs[iplName] then
        return
    end

    -- Si pas d'IPL requis (intérieur intégré), juste marquer comme déchargé
    if not iplData.ipl then
        LoadedIPLs[iplName] = nil
        return
    end

    RemoveIpl(iplData.ipl)

    if iplData.props and #iplData.props > 0 then
        for _, prop in ipairs(iplData.props) do
            if prop ~= iplData.ipl then
                RemoveIpl(prop)
            end
        end
    end

    LoadedIPLs[iplName] = nil
end

function IPLManager.IsIPLLoaded(iplName)
    return LoadedIPLs[iplName] == true
end

function IPLManager.GetIPLData(iplName)
    return IPLData[iplName]
end

function IPLManager.GetAvailableIPLs()
    local ipls = {}
    for iplName, data in pairs(IPLData) do
        table.insert(ipls, {
            name = iplName,
            displayName = data.name,
            category = data.category
        })
    end
    return ipls
end

function IPLManager.CleanupAll()

    for iplName, _ in pairs(LoadedIPLs) do
        IPLManager.UnloadIPL(iplName)
    end

    LoadedIPLs = {}
end

RegisterNetEvent("core:burglary:loadIPL")
AddEventHandler("core:burglary:loadIPL", function(iplName)
    IPLManager.LoadIPL(iplName)
end)

RegisterNetEvent("core:burglary:unloadIPL")
AddEventHandler("core:burglary:unloadIPL", function(iplName)
    IPLManager.UnloadIPL(iplName)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName then
        IPLManager.CleanupAll()
    end
end)

exports('GetIPLManager', function()
    return IPLManager
end)

return IPLManager