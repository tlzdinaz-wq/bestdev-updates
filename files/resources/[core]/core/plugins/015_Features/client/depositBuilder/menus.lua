local VUI = exports["VUI"]
local banner <const> = exports["core"]:GetVUIBanner("metier")

DepositMenu = {}
DepositMenu.pointId = nil
DepositMenu.label = nil

DepositMenu.main = VUI:CreateMenu("DÉPÔT", banner, true)

DepositMenu.main.OnOpen(function()
    DepositMenu.main.ClearItems()

    local label <const> = DepositMenu.label or "Dépôt"
   DepositMenu.main.Separator(label:upper())

    if not DepositMenu.pointId then
        DepositMenu.main.Button("ERREUR: AUCUN POINT", nil, nil, nil, true, function() end)
        return
    end

    DepositMenu.main.Button(":document: TOUT DÉPOSER", "Déposer tout votre inventaire", nil, "chevron", false, function()
        TriggerServerEvent("depositBuilder:server:depositAll", DepositMenu.pointId)
        DepositMenu.main.close()
    end)

    DepositMenu.main.Button(":document: TOUT RÉCUPÉRER", "Récupérer ce que vous avez déposé", nil, "chevron", false, function()
        TriggerServerEvent("depositBuilder:server:withdrawAll", DepositMenu.pointId)
        DepositMenu.main.close()
    end)
end)

function DepositMenu:Open(pointId, label)
    self.pointId = pointId
    self.label = label
    self.main.open()
end

DepositConsultMenu = {}
DepositConsultMenu.pointId = nil
DepositConsultMenu.label = nil

DepositConsultMenu.main = VUI:CreateMenu("CONSULTATION DÉPÔT", banner, true)

DepositConsultMenu.main.OnOpen(function()
    DepositConsultMenu.main.ClearItems()

    local label <const> = DepositConsultMenu.label or "Dépôt"
   DepositConsultMenu.main.Separator(label:upper())

    if not DepositConsultMenu.pointId then
        DepositConsultMenu.main.Button("ERREUR: AUCUN POINT", nil, nil, nil, true, function() end)
        return
    end

    local entries <const> = TriggerServerCallback("depositBuilder:getEntries", DepositConsultMenu.pointId) or {}

    if #entries == 0 then
        DepositConsultMenu.main.Button("AUCUN DÉPÔT", "Personne n'a déposé sur ce point", nil, nil, true, function() end)
        return
    end

    DepositConsultMenu.main.Separator(("DÉPOSITAIRES (%d)"):format(#entries))

    for i = 1, #entries do
        local entry <const> = entries[i]
        DepositConsultMenu.main.Button(
            ":user: " .. (entry.name or ("Citoyen " .. entry.citizenid)),
            "Consulter le dépôt (lecture seule)",
            nil,
            "chevron",
            false,
            function()
                TriggerServerEvent("depositBuilder:server:openEntry", DepositConsultMenu.pointId, entry.citizenid)
                DepositConsultMenu.main.close()
            end
        )
    end
end)

function DepositConsultMenu:Open(pointId, label)
    self.pointId = pointId
    self.label = label
    self.main.open()
end
