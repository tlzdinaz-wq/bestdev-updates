---@meta _
---@diagnostic disable: duplicate-doc-field

-- Permissions des tablettes (MDT police, tablette gouvernement).
--
-- Une seule source pour le client ET le serveur : l'interface attend une LISTE
-- [{ name, enabled }] et affiche une ligne par permission connue. Si la liste vivait en
-- double (un tableau côté client, un autre côté serveur), la moindre divergence donnerait
-- une case qui ne s'enregistre pas ou une permission invisible.
--
-- L'ordre est celui de la page Paramètres > Permissions.

VFW = VFW or {}

VFW.MdtPermissions = {
    -- MDT police / USSS / milice
    police = {
        "police_mdt_access",
        "manage_mdt_permissions",
        "search_citizens",
        "search_vehicles",
        "view_officers",
        "manage_announcements",
        "manage_wanted_citizens",
        "manage_wanted_vehicles",
        "access_prison",
        "access_cameras",
        "access_dossiers",
        "access_units",
        "access_bracelets",
        "view_logs",
        "manage_records",
        "manage_fines",
        "manage_wanted_notices",
        "manage_ppa",
        "delete_edit_records",
        "access_circulation",
    },

    -- Tablette gouvernement
    gouvernement = {
        "gouvernement_tablet",
        "gouvernement_settings",
        "security_actions",
        "view_citizens_info",
        "edit_citizen_phone",
        "edit_citizen_address",
        "edit_citizen_name",
        "view_citizen_vehicles",
        "view_citizen_properties",
        "view_citizen_finances",
        "manage_society_budget",
        "view_company_employees",
        "view_company_finances",
        "edit_company_address",
        "withdraw_company_funds",
        "deposit_company_funds",
        "manage_taxes",
        "manage_appointments",
        "accept_appointments",
        "delete_appointments",
        "chat_companies",
        "delete_messages",
        "create_invoice",
        "create_invoice_company",
    },
}

--- Liste [{ name, enabled }] attendue par les tablettes.
--- Un patron a tout : le serveur l'autorise déjà de son côté, l'interface doit montrer la
--- même chose plutôt qu'une tablette vide.
---@param kind string "police" | "gouvernement"
---@param granted table|nil permissions enregistrées (nom -> booléen)
---@param isBoss boolean|nil
---@return table
function VFW.BuildMdtPermissions(kind, granted, isBoss)
    local known = VFW.MdtPermissions[kind] or {}
    local saved = type(granted) == "table" and granted or {}
    local boss = isBoss == true
    local list, seen = {}, { isBoss = true }

    for i = 1, #known do
        local name = known[i]
        seen[name] = true
        list[i] = { name = name, enabled = boss or saved[name] == true }
    end

    -- Permissions ajoutées à la main en base et absentes de la liste ci-dessus : on les
    -- garde plutôt que de les effacer au premier enregistrement.
    for name, enabled in pairs(saved) do
        if type(name) == "string" and not seen[name] then
            list[#list + 1] = { name = name, enabled = boss or enabled == true }
        end
    end

    return list
end
