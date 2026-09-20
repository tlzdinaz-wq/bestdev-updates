---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.JobsPropsMenu = VFW.JobsPropsMenu or {}
VFW.JobsPropsMenu.registered = {} -- { [jobName] = { {model, name}, ... } }

--- Enregistrer un prop plaçable pour un ou plusieurs métiers
--- @param jobName string|string[] Nom(s) du job
--- @param model string Nom du modèle (ex: "prop_mp_cone_02")
--- @param displayName string Nom affiché (ex: "Cône de signalisation")
function VFW.JobsPropsMenu.AddProps(jobName, model, displayName)
    local jobs = type(jobName) == "table" and jobName or { jobName }
    for _, job in ipairs(jobs) do
        if not VFW.JobsPropsMenu.registered[job] then
            VFW.JobsPropsMenu.registered[job] = {}
        end
        table.insert(VFW.JobsPropsMenu.registered[job], {
            model = model,
            name = displayName
        })
    end
end

-- ═══════════════════════════════════════════════════════════
-- Enregistrement des props par métier
-- (doit rester APRÈS la définition de AddProps)
-- ═══════════════════════════════════════════════════════════

-- Liste centralisée des props police (auto-appliquée à tout job de type "police")
local policeProps = {
    -- Signalisation
    { "prop_mp_cone_02",          "Cône de signalisation" },
    { "prop_mp_cone_03",          "Cône de signalisation (grand)" },
    { "prop_barrier_work06a",     "Barrière de route" },
    { "prop_barrier_work01a",     "Barrière rayée" },
    { "prop_barrier_work05",      "Barrière métallique" },
    { "prop_roadcone02a",         "Cône routier" },
    { "prop_mp_arrow_barrier_01", "Barrière fléchée" },
    { "prop_barrier_wat_03b",     "Barrière eau" },
    -- Éclairage / Scène
    { "prop_worklight_03b",       "Projecteur sur trépied" },
    { "prop_worklight_03a",       "Projecteur au sol" },
    -- Mobilier terrain
    { "prop_table_04_chr",        "Table pliante" },
    { "prop_chair_08",            "Chaise pliante" },
    -- Sécurisation
    { "prop_barrel_01a",          "Barricade baril" },
    { "p_ld_stinger_s",           "Herse" },
}

local function jobAlreadyHasModel(jobName, model)
    local list = VFW.JobsPropsMenu.registered[jobName]
    if not list then return false end
    for _, p in ipairs(list) do
        if p.model == model then return true end
    end
    return false
end

-- Synchronise les props police pour TOUS les jobs de type police (rebuild auto via OnPoliceJobsListChange)
local function SyncPolicePropsRegistration()
    if not PoliceJobsList then return end
    for jobName in pairs(PoliceJobsList) do
        for _, def in ipairs(policeProps) do
            if not jobAlreadyHasModel(jobName, def[1]) then
                VFW.JobsPropsMenu.AddProps(jobName, def[1], def[2])
            end
        end
    end
end

if OnPoliceJobsListChange then
    OnPoliceJobsListChange(SyncPolicePropsRegistration)
else
    -- police_jobs.lua pas encore chargé : on attend
    CreateThread(function()
        while not OnPoliceJobsListChange do Wait(200) end
        OnPoliceJobsListChange(SyncPolicePropsRegistration)
    end)
end
