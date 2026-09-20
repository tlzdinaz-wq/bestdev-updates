-- Builder Gestion Gouvernement (menu staff F10)

local VUI <const> = exports["VUI"]
local adminBanner <const> = exports["core"]:GetVUIBanner("admin")

StaffMenu.builderGouv = VUI:CreateSubMenu(StaffMenu.builders, "GESTION GOUVERNEMENT", adminBanner, true)

StaffMenu.builderGouv.OnOpen(function()
    StaffMenu.builderGouv.ClearItems()
    StaffMenu.builderGouv.Separator("Accès rapide Gouvernement")
    StaffMenu.builderGouv.Button(
        "Tablette Gouvernement (toutes permissions)",
        "Ouvre la tablette gouvernement avec tous les droits.",
        nil,
        "chevron",
        false,
        function()
            TriggerEvent("gouv:openTablet")
        end
    )
    StaffMenu.builderGouv.Button(
        "Logs Actions",
        "Historique des actions terrain (menotter, escorter, fouille...)",
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderGouvLogsActions
    )
    StaffMenu.builderGouv.Button(
        "Logs MDT",
        "Historique des actions tablette (taxes, dépôts, retraits...)",
        nil,
        "chevron",
        false,
        function() end,
        StaffMenu.builderGouvLogsMDT
    )
end)

-- === Logs Actions (terrain) ===

local cachedActionsLogs = {}
local actionsLogsSearch = ""
local isActionsLogsRefreshing = false

StaffMenu.builderGouvLogsActions.OnOpen(function()
    StaffMenu.builderGouvLogsActions.ClearItems()
    StaffMenu.builderGouvLogsActions.Separator("LOGS ACTIONS (TERRAIN)")

    StaffMenu.builderGouvLogsActions.Button("Rechercher", "Filtrer par nom, action ou détails", nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher...", "")
        actionsLogsSearch = input or ""
      cachedActionsLogs = TriggerServerCallback("staff:getGouvLogs", { search = actionsLogsSearch, category = "actions" }) or {}
        isActionsLogsRefreshing = true
        StaffMenu.builderGouvLogsActions.refresh()
        isActionsLogsRefreshing = false
    end)

    if #cachedActionsLogs == 0 then
        cachedActionsLogs = TriggerServerCallback("staff:getGouvLogs", { search = actionsLogsSearch, category = "actions" }) or {}
    end

    if #cachedActionsLogs == 0 then
        StaffMenu.builderGouvLogsActions.Button("Aucun log", "Aucun historique enregistré", nil, "chevron", false, function() end)
        return
    end

    for _, log in ipairs(cachedActionsLogs) do
        local label = ("[%s] %s"):format(log.created_at_formatted or "?", log.action or "?")
        local desc = ("%s : %s"):format(log.player_name or "Inconnu", log.details or "")
        StaffMenu.builderGouvLogsActions.Button(label, desc, nil, "chevron", false, function() end)
    end
end)

StaffMenu.builderGouvLogsActions.OnClose(function()
    if not isActionsLogsRefreshing then
        cachedActionsLogs = {}
        actionsLogsSearch = ""
  end
end)

-- === Logs MDT (tablette) ===

local cachedMDTLogs = {}
local mdtLogsSearch = ""
local isMDTLogsRefreshing = false

StaffMenu.builderGouvLogsMDT.OnOpen(function()
    StaffMenu.builderGouvLogsMDT.ClearItems()
    StaffMenu.builderGouvLogsMDT.Separator("LOGS MDT (TABLETTE)")

    StaffMenu.builderGouvLogsMDT.Button("Rechercher", "Filtrer par nom, action ou détails", nil, "search", false, function()
        local input = VFW.Nui.KeyboardInput(true, "Rechercher...", "")
        mdtLogsSearch = input or ""
      cachedMDTLogs = TriggerServerCallback("staff:getGouvLogs", { search = mdtLogsSearch, category = "mdt" }) or {}
        isMDTLogsRefreshing = true
        StaffMenu.builderGouvLogsMDT.refresh()
        isMDTLogsRefreshing = false
    end)

    if #cachedMDTLogs == 0 then
        cachedMDTLogs = TriggerServerCallback("staff:getGouvLogs", { search = mdtLogsSearch, category = "mdt" }) or {}
    end

    if #cachedMDTLogs == 0 then
        StaffMenu.builderGouvLogsMDT.Button("Aucun log", "Aucun historique enregistré", nil, "chevron", false, function() end)
        return
    end

    for _, log in ipairs(cachedMDTLogs) do
        local label = ("[%s] %s"):format(log.created_at_formatted or "?", log.action or "?")
        local desc = ("%s : %s"):format(log.player_name or "Inconnu", log.details or "")
        StaffMenu.builderGouvLogsMDT.Button(label, desc, nil, "chevron", false, function() end)
    end
end)

StaffMenu.builderGouvLogsMDT.OnClose(function()
    if not isMDTLogsRefreshing then
        cachedMDTLogs = {}
        mdtLogsSearch = ""
  end
end)
