-- Métiers institutionnels livrés avec la base.
--
-- Les modules correspondants sont déjà là (tablette gouvernement, MDT SAMS, panneau USSS,
-- justice, presse), mais aucun métier ne portait leur nom : les boutons ne pouvaient donc
-- jamais apparaître dans le menu métier, et leurs tablettes étaient inaccessibles.
-- Chaque métier est créé une seule fois, uniquement s'il n'existe pas déjà : modifier un
-- métier en jeu (label, grades, position) ne sera jamais écrasé au redémarrage.
--
-- Pour ne pas livrer l'un d'eux, il suffit de retirer sa ligne JC.EnsureJob ci-dessous ;
-- pour le supprimer d'un serveur déjà démarré, passer par Builder > Modifier un métier.

VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

-- Convention de la base (voir le builder) : 98 = co-patron, 99 = patron. Le MDT SAMS
-- reconnaît d'ailleurs explicitement ces deux grades comme direction (BossGrades).
local function grades(list)
    local out = {}
    for i = 1, #list do out[i] = list[i] end
    out[#out + 1] = { grade = 98, name = "copatron", label = "Co-Patron", salary = 1600, is_boss = 1 }
    out[#out + 1] = { grade = 99, name = "boss", label = "Patron", salary = 2000, is_boss = 1 }
    return out
end

-- ── Secours : SAMS Pillbox et SAMS Paleto (plugins/015_Features/sn_sams) ───────────────
local SAMS_GRADES = grades({
    { grade = 0, name = "stagiaire", label = "Stagiaire", salary = 350, is_boss = 0 },
    { grade = 1, name = "ambulancier", label = "Ambulancier", salary = 550, is_boss = 0 },
    { grade = 2, name = "medecin", label = "Medecin", salary = 800, is_boss = 0 },
    { grade = 3, name = "chirurgien", label = "Chirurgien", salary = 1100, is_boss = 0 },
    { grade = 4, name = "chef_service", label = "Chef de service", salary = 1400, is_boss = 0 },
})

JC.EnsureJob("sams_pib", "SAMS Pillbox", "ambulance", SAMS_GRADES)
JC.EnsureJob("sams_pab", "SAMS Paleto", "ambulance", SAMS_GRADES)

-- ── Gouvernement (plugins/015_Features/client/jobs/gouvernement) ───────────────────────
JC.EnsureJob("gouvernement", "Gouvernement", "gouvernement", grades({
    { grade = 0, name = "stagiaire", label = "Stagiaire", salary = 500, is_boss = 0 },
    { grade = 1, name = "agent", label = "Agent administratif", salary = 800, is_boss = 0 },
    { grade = 2, name = "conseiller", label = "Conseiller", salary = 1100, is_boss = 0 },
    { grade = 3, name = "ministre", label = "Ministre", salary = 1500, is_boss = 0 },
}))

-- ── USSS : type "police" pour être reconnu par le dispatch et les alertes ──────────────
JC.EnsureJob("usss", "USSS", "police", grades({
    { grade = 0, name = "recrue", label = "Recrue", salary = 600, is_boss = 0 },
    { grade = 1, name = "agent", label = "Agent", salary = 900, is_boss = 0 },
    { grade = 2, name = "agent_special", label = "Agent special", salary = 1200, is_boss = 0 },
    { grade = 3, name = "superviseur", label = "Superviseur", salary = 1600, is_boss = 0 },
}))

-- ── Justice (plugins/015_Features/client/jobs/justice) ─────────────────────────────────
JC.EnsureJob("doj", "Department of Justice", "justice", grades({
    { grade = 0, name = "greffier", label = "Greffier", salary = 600, is_boss = 0 },
    { grade = 1, name = "avocat", label = "Avocat", salary = 1000, is_boss = 0 },
    { grade = 2, name = "procureur", label = "Procureur", salary = 1400, is_boss = 0 },
    { grade = 3, name = "juge", label = "Juge", salary = 1800, is_boss = 0 },
}))

-- ── Presse (plugins/015_Features/client/jobs/lifeinvader + outils journaliste) ─────────
local PRESSE_GRADES = grades({
    { grade = 0, name = "stagiaire", label = "Stagiaire", salary = 350, is_boss = 0 },
    { grade = 1, name = "journaliste", label = "Journaliste", salary = 600, is_boss = 0 },
    { grade = 2, name = "reporter", label = "Grand reporter", salary = 900, is_boss = 0 },
    { grade = 3, name = "redacteur", label = "Redacteur en chef", salary = 1300, is_boss = 0 },
})

JC.EnsureJob("lifeinvader", "LifeInvader", "other", PRESSE_GRADES)
JC.EnsureJob("weazelnews", "Weazel News", "other", PRESSE_GRADES)
