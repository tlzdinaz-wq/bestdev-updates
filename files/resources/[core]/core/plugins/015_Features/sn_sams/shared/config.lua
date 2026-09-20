---@meta _
---@diagnostic disable: duplicate-doc-field

SN_SAMS = SN_SAMS or {}

SN_SAMS.Logo = VFW.CDN.Get("job/sams/sams_logo.png")

SN_SAMS.Config = {
    -- Jobs autorisés
    Jobs = {
        "sams_pib",
        "sams_pab",
    },

    -- Hôpitaux avec coordonnées (pour calcul distance)
    Hospitals = {
        pillbox = {
            label = "Pillbox Hill",
            coords = vector3(311.2, -593.0, 43.3)
        },
        paleto = {
            label = "Paleto Bay",
            coords = vector3(-247.8, 6331.4, 32.4)
        }
    },

    -- Grades boss / co-boss (ont toutes les permissions automatiquement)
    BossGrades = { 99, 98 },

    -- Permissions disponibles
    Permissions = {
        "create_announcement",
        "delete_announcement",
        "edit_announcement",
        "create_report",
        "delete_report",
        "edit_report",
        "create_invoice",
        "cancel_invoice",
        "add_note",
        "delete_note",
        "take_alert",
        "manage_permissions",
        "create_treatment",
        "edit_treatment",
        "delete_treatment",
        "create_procedure",
        "edit_procedure",
        "delete_procedure",
        "pharmacy_society_payment",
        "pharmacy_buy_sams_items",
        "create_document",
        "manage_ppa",
    },

    -- Debug mode
    Debug = false,
}

--- Vérifie si le joueur a un job SAMS/médical
---@return boolean
function SN_SAMS.HasJob()
    local job = VFW.PlayerData.job
    if not job then return false end
    for _, j in ipairs(SN_SAMS.Config.Jobs) do
        if job.name == j then
            return true
        end
    end
    return false
end

--- Vérifie si le joueur est en service
---@return boolean
function SN_SAMS.IsOnDuty()
    local job = VFW.PlayerData.job
    return job ~= nil and SN_SAMS.HasJob() and job.onDuty
end
