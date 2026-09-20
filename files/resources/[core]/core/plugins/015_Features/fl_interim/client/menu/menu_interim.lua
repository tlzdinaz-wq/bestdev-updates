
local VUI = exports["VUI"]

local RES = GetCurrentResourceName()

local PlayerData

RegisterNetEvent("vfw:playerLoaded", function(playerData)
    PlayerData = playerData
end)

local function ratingToPct(n) if type(n)~="number" then return 0 end if n<0 then n=0 elseif n>5 then n=5 end return n*20 end

local FALLBACK_MAIN_TITLE   = (Interim.ui.menus.main   and Interim.ui.menus.main.title)   or "CENTRE D'INTÉRIM"
local FALLBACK_MAIN_BANNER  = (Interim.ui.menus.main   and Interim.ui.menus.main.banner)  or "interim"
local FALLBACK_CHOOSE_TITLE = (Interim.ui.menus.choose and Interim.ui.menus.choose.title) or "CHOISIR UN MÉTIER D'INTÉRIM"
local FALLBACK_CHOOSE_BANNER= (Interim.ui.menus.choose and Interim.ui.menus.choose.banner)or "interim"

Interim.main   = VUI:CreateMenu(FALLBACK_MAIN_TITLE,   FALLBACK_MAIN_BANNER,  true)
Interim.choose = VUI:CreateSubMenu(Interim.main, FALLBACK_CHOOSE_TITLE, FALLBACK_CHOOSE_BANNER, true)

local function ApplyUiFromConfig(doRefresh)
    local main  = Interim.ui.menus.main   or {}
    local choose= Interim.ui.menus.choose or {}

    if main.title  then Interim.main.title  = main.title  end
    if main.banner then Interim.main.ChangeBanner(main.banner) end

    if choose.title  then Interim.choose.title  = choose.title  end
    if choose.banner then Interim.choose.ChangeBanner(choose.banner) end


    if doRefresh then
        if Interim.main.opened then Interim.main.refresh() end
        if Interim.choose.opened then Interim.choose.refresh() end
    end
end

RegisterNetEvent("interim:client:uiUpdated", function()
    ApplyUiFromConfig(true)
end)



local function showPreview(job)
    local meta = Interim.JOB_META[job.id] or {}
    local previewData = {
        { type = "header", iconUrl = "job.png",     label = "",             value = tostring(job.label:upper()) },
        { type = "body",   iconUrl = "info.png",    label = "Description",  value = tostring(job.desc or "-") },
        { type = "body",   iconUrl = "time.png",    label = "Horaires",     value = tostring(meta.hours or "Variables") },
        { type = "body",   iconUrl = "map.png",     label = "Zone",         value = tostring(meta.zone or "-") },
        { type = "body",   iconUrl = "car.png",     label = "Véhicule",     value = tostring(meta.vehicle or "-") },
        { type = "body",   iconUrl = "shield.png",  label = "Requis",       value = tostring(meta.requirements or "Aucun") },
    }
    local stats = {
        { "Stat 1", ratingToPct(0) },
        { "Stat 2", ratingToPct(0) },
        { "Stat 3", ratingToPct(0) },
    }
    Interim.main.PlayerPreview(job.image, nil, previewData, stats)
end

local function chooseJob(job)
    if not job then return end


    TriggerServerEvent("interim:chooseJob", job.id)
    Interim.main.PlayerPreview()
    Interim.main.close()
end

local function findJobByTitle(title)
    if not title then return nil end
    for _, j in ipairs(Interim.jobs) do
        if j.label == title then return j end
    end
    return nil
end

local function getVisibleItems()
    if Interim.choose.isFiltered and Interim.choose:isFiltered() then
        return Interim.choose.filterItems
    end
    return Interim.choose.items
end

local function resolveJob(index, item)
    if item and item.props and item.props.title then
        local j = findJobByTitle(item.props.title)
        if j then return j end
    end
    local items = getVisibleItems()
    local it = index and items and items[index]
    if it and it.props and it.props.title then
        local j = findJobByTitle(it.props.title)
        if j then return j end
    end
    if index and Interim.data.indexToJob[index] then
        return Interim.data.indexToJob[index]
    end
    return nil
end


function Interim.BuildMainMenu()


    Interim.main.ClearItems()
    Interim.main.Button("Choisir un métier d'intérim", nil, nil, "chevron", false, function() end, Interim.choose)
end

function Interim.BuildChooseMenu()
    if Interim.choose.isFiltered and Interim.choose:isFiltered() then
        Interim.choose.removeFilter()
    end
    Interim.choose.ClearItems()
    if not Interim.jobs or #Interim.jobs == 0 then
        Interim.choose.Title("Job", "", "", "", nil)
        Interim.choose.Textbox("Chargement de la configuration…", "Veuillez patienter")
        Interim.main.PlayerPreview()
        return
    end
    Interim.data.indexToJob = {}

    Interim.choose.Title("Liste des métiers disponibles", "", "", "", nil)

    for _, job in ipairs(Interim.jobs) do
        Interim.data.indexToJob[#Interim.choose.items + 1] = job
        Interim.choose.Button(job.label, nil, nil, nil, false, function()
            chooseJob(job)
        end)
    end

    Interim.choose.Separator(nil)

end


Interim.main.OnOpen(function()


    Interim.BuildMainMenu()
end)

Interim.main.OnClose(function()
    Interim.main.PlayerPreview()
    Interim.main.ClearItems()
end)

Interim.choose.OnOpen(function()
    Interim.BuildChooseMenu()
end)

Interim.choose.OnClose(function()
    Interim.main.PlayerPreview()
    Interim.choose.ClearItems()
end)

Interim.choose.OnIndexChange(function(index, item)
    local function getVisibleItems()
        if Interim.choose.isFiltered and Interim.choose:isFiltered() then
            return Interim.choose.filterItems
        end
        return Interim.choose.items
    end

    local items = getVisibleItems()
    local lastIndex = #items

    local useIndex = index
    local useItem  = item

    if useIndex == 1 or not useItem or useItem.type == "separator" or useIndex == lastIndex then
        useIndex = 2
        useItem  = (items and items[2]) or nil
    end

    local job = resolveJob(useIndex, useItem)

    if not job and Interim.data.indexToJob[2] then
        job = Interim.data.indexToJob[2]
    end
    if not job then
        for _, j in ipairs(Interim.jobs) do
            if j.id == "pizza" or j.label == "Livreur de Pizza" then
                job = j
                break
            end
        end
    end

    if job then
        showPreview(job)
        Interim.choose.index = useIndex
    else
        Interim.main.PlayerPreview()
    end
end)
