VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

JC.EnsureJob("dynasty", "Dynasty 8", "dynasty", {
    { grade = 0, name = "agent", label = "Agent immobilier", salary = 350, is_boss = 0 },
    { grade = 1, name = "negociateur", label = "Negociateur", salary = 550, is_boss = 0 },
    { grade = 2, name = "directeur", label = "Directeur d'agence", salary = 850, is_boss = 0 },
    { grade = 3, name = "boss", label = "Patron", salary = 1200, is_boss = 1 },
})
