VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

local POLICE_GRADES = {
    { grade = 0, name = "cadet", label = "Cadet", salary = 400, is_boss = 0 },
    { grade = 1, name = "officier", label = "Officier", salary = 650, is_boss = 0 },
    { grade = 2, name = "sergent", label = "Sergent", salary = 900, is_boss = 0 },
    { grade = 3, name = "lieutenant", label = "Lieutenant", salary = 1200, is_boss = 0 },
    { grade = 4, name = "capitaine", label = "Capitaine", salary = 1500, is_boss = 0 },
    { grade = 5, name = "boss", label = "Commandant", salary = 1900, is_boss = 1 },
}

JC.EnsureJob("police", "SASP SUD", "police", POLICE_GRADES)
JC.EnsureJob("sheriff", "SASP NORD", "police", POLICE_GRADES)
