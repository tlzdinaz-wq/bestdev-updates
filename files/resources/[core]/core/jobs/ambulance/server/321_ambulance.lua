VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

JC.EnsureJob("ambulance", "EMS", "ambulance", {
    { grade = 0, name = "stagiaire", label = "Stagiaire", salary = 350, is_boss = 0 },
    { grade = 1, name = "ambulancier", label = "Ambulancier", salary = 550, is_boss = 0 },
    { grade = 2, name = "medecin", label = "Medecin", salary = 800, is_boss = 0 },
    { grade = 3, name = "chirurgien", label = "Chirurgien", salary = 1100, is_boss = 0 },
    { grade = 4, name = "boss", label = "Chef de service", salary = 1500, is_boss = 1 },
})
