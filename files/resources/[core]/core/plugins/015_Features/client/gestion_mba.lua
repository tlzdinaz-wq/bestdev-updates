local mbaAllEntitySets = {
    'mba_trackmania_04', 'mba_trackmania_03', 'mba_trackmania_02', 'mba_trackmania_01',
    'mba_gokart_02', 'mba_gokart_01', 'mba_hockey', 'mba_field', 'mba_soccer',
    'mba_rocketleague', 'mba_curling', 'mba_tribune', 'mba_cover', 'mba_tarps',
    'mba_chairs', 'mba_basketball', 'mba_derby', 'mba_paintball', 'mba_fighting',
    'mba_wrestling', 'mba_mma', 'mba_boxing', 'mba_backstage', 'mba_concert',
    'mba_fashion', 'mba_fameorshame', 'mba_ring_of_fire', 'mba_jumbotron', 'mba_terrain',
}

local mbaEntitySets = {
    ["BASKETBALL"]   = { 'mba_tribune', 'mba_tarps', 'mba_basketball', 'mba_jumbotron' },
    ["BOXING"]       = { 'mba_tribune', 'mba_tarps', 'mba_fighting', 'mba_boxing', 'mba_jumbotron' },
    ["CONCERT"]      = { 'mba_tribune', 'mba_tarps', 'mba_backstage', 'mba_concert', 'mba_jumbotron' },
    ["CURLING"]      = { 'mba_tribune', 'mba_chairs', 'mba_curling' },
    ["DERBY"]        = { 'mba_cover', 'mba_terrain', 'mba_derby', 'mba_ring_of_fire' },
    ["FAMEorSHAME"]  = { 'mba_tribune', 'mba_tarps', 'mba_backstage', 'mba_fameorshame', 'mba_jumbotron' },
    ["FASHION"]      = { 'mba_tribune', 'mba_tarps', 'mba_backstage', 'mba_fashion', 'mba_jumbotron' },
    ["FOOTBALL"]     = { 'mba_tribune', 'mba_chairs', 'mba_field', 'mba_soccer' },
    ["ICEHOCKEY"]    = { 'mba_tribune', 'mba_chairs', 'mba_field', 'mba_hockey' },
    ["GOKARTA"]      = { 'mba_cover', 'mba_gokart_01' },
    ["GOKARTB"]      = { 'mba_cover', 'mba_gokart_02' },
    ["TRACKMANIAA"]  = { 'mba_trackmania_01', 'mba_cover' },
    ["TRACKMANIAB"]  = { 'mba_trackmania_02', 'mba_cover' },
    ["TRACKMANIAC"]  = { 'mba_trackmania_03', 'mba_cover' },
    ["TRACKMANIAD"]  = { 'mba_trackmania_04', 'mba_cover' },
    ["MMA"]          = { 'mba_tribune', 'mba_tarps', 'mba_fighting', 'mba_mma', 'mba_jumbotron' },
    ["EMPTY"]        = { 'mba_tribune', 'mba_tarps', 'mba_jumbotron' },
    ["PAINTBALL"]    = { 'mba_tribune', 'mba_chairs', 'mba_paintball', 'mba_jumbotron' },
    ["ROCKETLEAGUE"] = { 'mba_tribune', 'mba_chairs', 'mba_rocketleague' },
    ["WRESTLING"]    = { 'mba_tribune', 'mba_tarps', 'mba_fighting', 'mba_wrestling', 'mba_jumbotron' },
}

local mbaSigns = {
    ["BASKETBALL"]   = 'gabz_ipl_mba_sign_basketball',
    ["BOXING"]       = 'gabz_ipl_mba_sign_boxing',
    ["CONCERT"]      = 'gabz_ipl_mba_sign_concert',
    ["CURLING"]      = 'gabz_ipl_mba_sign_curling',
    ["DERBY"]        = 'gabz_ipl_mba_sign_derby',
    ["FAMEorSHAME"]  = 'gabz_ipl_mba_sign_fameorshame',
    ["FASHION"]      = 'gabz_ipl_mba_sign_fashion',
    ["FOOTBALL"]     = 'gabz_ipl_mba_sign_soccer',
    ["ICEHOCKEY"]    = 'gabz_ipl_mba_sign_icehockey',
    ["GOKARTA"]      = 'gabz_ipl_mba_sign_gokart',
    ["GOKARTB"]      = 'gabz_ipl_mba_sign_gokart',
    ["TRACKMANIAA"]  = 'gabz_ipl_mba_sign_banditomania',
    ["TRACKMANIAB"]  = 'gabz_ipl_mba_sign_banditomania',
    ["TRACKMANIAC"]  = 'gabz_ipl_mba_sign_banditomania',
    ["TRACKMANIAD"]  = 'gabz_ipl_mba_sign_banditomania',
    ["MMA"]          = 'gabz_ipl_mba_sign_mma',
    ["PAINTBALL"]    = 'gabz_ipl_mba_sign_paintball',
    ["ROCKETLEAGUE"] = 'gabz_ipl_mba_sign_banditoleague',
    ["WRESTLING"]    = 'gabz_ipl_mba_sign_wrestling',
}

local allSigns = {
    'gabz_ipl_mba_sign_basketball', 'gabz_ipl_mba_sign_boxing',
    'gabz_ipl_mba_sign_concert', 'gabz_ipl_mba_sign_curling',
    'gabz_ipl_mba_sign_derby', 'gabz_ipl_mba_sign_fameorshame',
    'gabz_ipl_mba_sign_fashion', 'gabz_ipl_mba_sign_soccer',
    'gabz_ipl_mba_sign_icehockey', 'gabz_ipl_mba_sign_gokart',
    'gabz_ipl_mba_sign_banditomania', 'gabz_ipl_mba_sign_mma',
    'gabz_ipl_mba_sign_paintball', 'gabz_ipl_mba_sign_banditoleague',
    'gabz_ipl_mba_sign_wrestling',
}

local pendingMBASet = nil
local mbaApplied = false

local function applyMBAEntitySet(setKey)
    local sets = mbaEntitySets[setKey]
    if not sets then return false end

    local interior = GetInteriorAtCoords(-324.22, -1968.49, 20.60)
    if interior == 0 then
        pendingMBASet = setKey
        mbaApplied = false
        return false
    end

    for _, s in ipairs(mbaAllEntitySets) do
        DeactivateInteriorEntitySet(interior, s)
    end

    Wait(100)

    for _, s in ipairs(sets) do
        ActivateInteriorEntitySet(interior, s)
    end

    RefreshInterior(interior)

    for _, sign in ipairs(allSigns) do
        RemoveIpl(sign)
    end
    local newSign = mbaSigns[setKey]
    if newSign then
        RequestIpl(newSign)
    end

    pendingMBASet = setKey
    mbaApplied = true
    return true
end

RegisterNetEvent('MBA:SendEntitySet', function(setKey)
    applyMBAEntitySet(setKey)
end)

Citizen.CreateThread(function()
    while true do
        if pendingMBASet and not mbaApplied then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            if #(coords - vector3(-324.22, -1968.49, 20.60)) < 500.0 then
                applyMBAEntitySet(pendingMBASet)
            end
        end
        Wait(5000)
    end
end)

AddEventHandler('vfw:playerLoaded', function()
    Wait(2000)
    TriggerServerEvent('MBA:AskForEntitySet')
    TriggerServerEvent('Church1:AskForEntitySet')
    TriggerServerEvent('Church2:AskForEntitySet')
    TriggerServerEvent('Church3:AskForEntitySet')
end)
