VFW.JobsCommon = VFW.JobsCommon or {}

local JC = VFW.JobsCommon

JC.EnsureJob("milice", "Milice", "milice", {
    { grade = 0, name = "recrue", label = "Recrue", salary = 300, is_boss = 0 },
    { grade = 1, name = "milicien", label = "Milicien", salary = 500, is_boss = 0 },
    { grade = 2, name = "sergent", label = "Sergent", salary = 700, is_boss = 0 },
    { grade = 3, name = "boss", label = "Commandant", salary = 1000, is_boss = 1 },
})
