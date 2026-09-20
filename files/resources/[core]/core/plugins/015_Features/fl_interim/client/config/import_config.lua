

Interim = rawget(_G, "Interim") or {}
Interim.jobs = Interim.jobs or {}
Interim.JOB_META = Interim.JOB_META or {}
Interim.data = Interim.data or { indexToJob = {} }
Interim.ui   = Interim.ui   or { menus = {} }
Interim.ui.menus = Interim.ui.menus or {}


local RES = GetCurrentResourceName()

local function resolveImage(pathOrUrl)
    if type(pathOrUrl) ~= "string" then return nil end
    if pathOrUrl:match("^https?://") or pathOrUrl:match("^nui://") then
        return pathOrUrl
    end
    return ('nui://%s/%s'):format(RES, pathOrUrl)
end

local function applyConfig(cfg)
    if not cfg or not cfg.jobs then return end

    Interim.jobs = {}
    Interim.JOB_META = {}
    Interim.data.indexToJob = {}
    Interim.ui.menus = cfg.ui and cfg.ui.menus or {
        main   = { title = "CENTRE D'INTÉRIM",            banner = "default" },
        choose = { title = "CHOISIR UN MÉTIER D'INTÉRIM", banner = "default" },
    }


    local order = cfg.order or {}
    local tmp, byId = {}, {}

    for id, data in pairs(cfg.jobs) do
        table.insert(tmp, {
            id    = id,
            label = data.label,
            image = resolveImage(data.image),
            desc  = data.desc or "",
            _ord  = (function()
                for i, oid in ipairs(order) do if oid == id then return i end end
                return 999
            end)()
        })
        Interim.JOB_META[id] = data.meta or {}
    end

    table.sort(tmp, function(a,b) return a._ord < b._ord end)
    for _, j in ipairs(tmp) do
        j._ord = nil
        table.insert(Interim.jobs, j)
        byId[j.id] = j
    end

    if cfg.indexToJob then
        for idx, jobId in pairs(cfg.indexToJob) do
            local job = byId[jobId]
            if job then
                Interim.data.indexToJob[tonumber(idx)] = job
            end
        end
    else
        local start = 2
        for i, job in ipairs(Interim.jobs) do
            Interim.data.indexToJob[start + i - 1] = job
        end
    end


    TriggerEvent("interim:client:uiUpdated")
end

RegisterNetEvent("interim:receiveConfig", function(cfg)
    applyConfig(cfg)
end)

function EnsureConfigLoaded()
    TriggerServerEvent("interim:requestConfig")
end

AddEventHandler("onClientResourceStart", function(res)
    if res ~= RES then return end
    TriggerServerEvent("interim:requestConfig")
    SetTimeout(3000, function()
        TriggerServerEvent("interim:requestConfig")
    end)
end)
