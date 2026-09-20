local exams = {}

local LICENSE_LABELS = {
    car = "Permis Voiture",
    motorcycle = "Permis Moto",
    truck = "Permis Poids Lourd",
}

local function dvmCfg()
    if type(Config) == "table" and type(Config.DVM) == "table" then return Config.DVM end
    return nil
end

local function generalCfg()
    local c = dvmCfg()
    if c and type(c.General) == "table" then return c.General end
    return {}
end

local function licenseCfg(licenseType)
    local c = dvmCfg()
    if not c or type(c.LicenseTypes) ~= "table" then return nil end
    return c.LicenseTypes[licenseType]
end

local function examCost(examType)
    local g = generalCfg()
    local costs = type(g.ExamCost) == "table" and g.ExamCost or {}
    if examType == "code" then return tonumber(costs.code) or 500 end
    return tonumber(costs.driving) or 1000
end

local function charge(xPlayer, amount, method, reason)
    if amount <= 0 then return true end
    if method == "cash" or method == "money" then
        local account = xPlayer.getAccount("money")
        local balance = type(account) == "table" and (account.money or account.amount or 0) or (tonumber(account) or 0)
        if balance < amount then return false end
        xPlayer.removeAccountMoney("money", amount, reason)
        return true
    end

    local account = xPlayer.getAccount("bank")
    local balance = type(account) == "table" and (account.money or account.amount or 0) or (tonumber(account) or 0)
    if balance < amount then return false end
    xPlayer.removeAccountMoney("bank", amount, reason)
    return true
end

local function hasLicense(identifier, licenseType)
    local row = MiscB.Single(
        "SELECT id FROM dvm_licenses WHERE identifier = ? AND license_type = ? LIMIT 1",
        { identifier, licenseType }
    )
    return row ~= nil
end

local function grantLicense(xPlayer, licenseType, score)
    if hasLicense(xPlayer.identifier, licenseType) then return end
    MiscB.Insert([[
        INSERT INTO dvm_licenses (identifier, char_id, license_type, score, obtained_at)
        VALUES (?, ?, ?, ?, NOW())
    ]], { xPlayer.identifier, xPlayer.charId, licenseType, score or 0 })

    if xPlayer.addLicense then
        pcall(xPlayer.addLicense, "dvm_" .. licenseType, LICENSE_LABELS[licenseType] or licenseType)
    end
end

local function logAttempt(xPlayer, examType, licenseType, score, passed, bribed)
    MiscB.Insert([[
        INSERT INTO dvm_exam_history (identifier, char_id, exam_type, license_type, score, passed, bribed, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ]], { xPlayer.identifier, xPlayer.charId, examType, licenseType, score or 0, passed and 1 or 0, bribed and 1 or 0 })
end

local function attemptsToday(identifier)
    return MiscB.Scalar([[
        SELECT COUNT(*) FROM dvm_exam_history
        WHERE identifier = ? AND DATE(created_at) = CURDATE()
    ]], { identifier }, 0)
end

local function pickQuestions(licenseType, count)
    local c = dvmCfg()
    if not c or type(c.CodeQuestions) ~= "table" then return {} end

    local pool = {}
    local general = c.CodeQuestions.general
    if type(general) == "table" then
        for i = 1, #general do pool[#pool + 1] = general[i] end
    end
    local specific = c.CodeQuestions[licenseType]
    if type(specific) == "table" then
        for i = 1, #specific do pool[#pool + 1] = specific[i] end
    end

    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end

    local out = {}
    local total = math.min(count or 20, #pool)
    for i = 1, total do
        local q = pool[i]
        out[#out + 1] = {
            id = q.id,
            question = q.question,
            answers = q.answers,
            explanation = q.explanation,
        }
    end
    return out, pool
end

local function routeFor(licenseType, centerIndex)
    local c = dvmCfg()
    if not c or type(c.DrivingRoutes) ~= "table" then return nil end
    local list = c.DrivingRoutes[licenseType]
    if type(list) ~= "table" or #list == 0 then return nil end

    for i = 1, #list do
        if tonumber(list[i].examCenter) == tonumber(centerIndex) then return list[i] end
    end
    return list[1]
end

MiscB.Cb("dvm:getCurrentDate", function(source)
    return os.date("%d/%m/%Y")
end)

MiscB.Cb("dvm:getPlayerLicenses", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { licenses = {} } end

    local rows = MiscB.Query([[
        SELECT license_type, score, obtained_at FROM dvm_licenses
        WHERE identifier = ? ORDER BY id ASC
    ]], { xPlayer.identifier })

    for i = 1, #rows do
        rows[i].label = LICENSE_LABELS[rows[i].license_type] or rows[i].license_type
    end

    return { licenses = rows }
end)

MiscB.Cb("dvm:getPlayerLicensesForDocument", function(source, targetServerId)
    local target = tonumber(targetServerId) or source
    local xTarget = VFW.GetPlayerFromId(target)
    if not xTarget then return { licenses = {} } end

    local rows = MiscB.Query([[
        SELECT license_type, score, obtained_at FROM dvm_licenses
        WHERE identifier = ? ORDER BY id ASC
    ]], { xTarget.identifier })

    local owned = { A = false, B = false, C = false }
    for i = 1, #rows do
        if rows[i].license_type == "motorcycle" then owned.A = true end
        if rows[i].license_type == "car" then owned.B = true end
        if rows[i].license_type == "truck" then owned.C = true end
    end

    return {
        licenses = rows,
        categories = owned,
        firstName = xTarget.firstName or "",
        lastName = xTarget.lastName or "",
        dateofbirth = xTarget.dateofbirth or "",
        photo = xTarget.mugshot or nil,
    }
end)

MiscB.Cb("dvm:getExamHistory", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { history = {} } end

    local rows = MiscB.Query([[
        SELECT exam_type, license_type, score, passed, created_at
        FROM dvm_exam_history WHERE identifier = ? ORDER BY id DESC LIMIT 50
    ]], { xPlayer.identifier })

    return { history = rows }
end)

MiscB.Cb("dvm:startCodeExama", function(source, licenseType, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local lType = MiscB.Str(licenseType, 32)
    local cfg = lType and licenseCfg(lType)
    if not cfg then return { success = false, message = "Ce type de permis n'est pas valide." } end

    if hasLicense(xPlayer.identifier, lType) then
        return { success = false, message = "Vous possedez deja ce permis." }
    end

    local g = generalCfg()
    local maxAttempts = tonumber(g.MaxAttempts) or 3
    if attemptsToday(xPlayer.identifier) >= maxAttempts then
        return { success = false, message = "Vous avez atteint le nombre maximum de tentatives aujourd'hui." }
    end

    local cost = examCost("code")
    if not charge(xPlayer, cost, paymentMethod, "dvm-code") then
        return { success = false, message = "Fonds insuffisants." }
    end

    local questions, pool = pickQuestions(lType, tonumber(cfg.codeQuestions) or 20)
    if #questions == 0 then
        return { success = false, message = "Aucune question disponible." }
    end

    local answerKey = {}
    for i = 1, #pool do
        answerKey[tostring(pool[i].id)] = pool[i].correct
    end

    exams[source] = {
        type = "code",
        licenseType = lType,
        answerKey = answerKey,
        questionIds = {},
        startedAt = os.time(),
    }
    for i = 1, #questions do
        exams[source].questionIds[#exams[source].questionIds + 1] = questions[i].id
    end

    return {
        success = true,
        questions = questions,
        timeLimit = tonumber(cfg.codeTimeLimit) or (#questions * 30),
        licenseType = lType,
    }
end)

MiscB.Cb("dvm:finishCodeExam", function(source, answers)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local exam = exams[source]
    if not exam or exam.type ~= "code" then
        return { success = false, message = "Aucun examen en cours." }
    end
    exams[source] = nil

    if type(answers) ~= "table" then answers = {} end

    local total = #exam.questionIds
    local correct = 0
    for i = 1, total do
        local qid = exam.questionIds[i]
        local expected = exam.answerKey[tostring(qid)]
        local given = answers[tostring(qid)]
        if given == nil then given = answers[qid] end
        if given == nil then given = answers[i] end
        if expected ~= nil and tonumber(given) == tonumber(expected) then
            correct = correct + 1
        end
    end

    local score = total > 0 and math.floor((correct / total) * 100) or 0
    local passScore = tonumber(generalCfg().CodePassingScore) or 80
    local passed = score >= passScore

    logAttempt(xPlayer, "code", exam.licenseType, score, passed, false)

    if passed then
        MiscB.Insert([[
            INSERT INTO dvm_code_passed (identifier, license_type, score, created_at)
            VALUES (?, ?, ?, NOW())
        ]], { xPlayer.identifier, exam.licenseType, score })
    end

    return {
        success = true,
        passed = passed,
        score = score,
        correct = correct,
        total = total,
        passingScore = passScore,
        licenseType = exam.licenseType,
    }
end)

MiscB.Cb("dvm:startDrivingExam", function(source, licenseType, centerIndex, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false, message = "Joueur introuvable." } end

    local lType = MiscB.Str(licenseType, 32)
    local cfg = lType and licenseCfg(lType)
    if not cfg then return { success = false, message = "Ce type de permis n'est pas valide." } end

    if hasLicense(xPlayer.identifier, lType) then
        return { success = false, message = "Vous possedez deja ce permis." }
    end

    local codePassed = MiscB.Single(
        "SELECT id FROM dvm_code_passed WHERE identifier = ? AND license_type = ? LIMIT 1",
        { xPlayer.identifier, lType }
    )
    if not codePassed then
        return { success = false, message = "Vous devez d'abord reussir le code." }
    end

    if type(cfg.prerequisites) == "table" then
        for i = 1, #cfg.prerequisites do
            if not hasLicense(xPlayer.identifier, cfg.prerequisites[i]) then
                return { success = false, message = "Il vous manque un permis prerequis." }
            end
        end
    end

    local g = generalCfg()
    local maxAttempts = tonumber(g.MaxAttempts) or 3
    if attemptsToday(xPlayer.identifier) >= maxAttempts then
        return { success = false, message = "Vous avez atteint le nombre maximum de tentatives aujourd'hui." }
    end

    local route = routeFor(lType, centerIndex)
    if not route then return { success = false, message = "Aucun parcours disponible." } end

    local cost = examCost("driving")
    if not charge(xPlayer, cost, paymentMethod, "dvm-conduite") then
        return { success = false, message = "Fonds insuffisants." }
    end

    exams[source] = {
        type = "driving",
        licenseType = lType,
        violations = {},
        checkpoint = 0,
        totalCheckpoints = type(route.checkpoints) == "table" and #route.checkpoints or 0,
        startedAt = os.time(),
    }

    return {
        success = true,
        route = route,
        vehicleModel = cfg.examVehicle,
        instructorModel = cfg.instructorModel,
        instructorVehicle = cfg.instructorVehicle,
        timeLimit = cfg.drivingTime,
        licenseType = lType,
    }
end)

RegisterNetEvent("dvm:addViolation", function(violation)
    local source = source
    if type(violation) ~= "table" then return end

    local exam = exams[source]
    if not exam or exam.type ~= "driving" then return end
    if #exam.violations >= 50 then return end

    exam.violations[#exam.violations + 1] = {
        type = MiscB.Str(violation.type, 64) or "unknown",
        label = MiscB.Str(violation.label, 128) or "",
        penalty = MiscB.ToInt(violation.penalty, 0, 100) or 5,
    }
end)

RegisterNetEvent("dvm:updateDrivingCheckpoint", function(currentCheckpoint)
    local source = source
    local cp = MiscB.ToInt(currentCheckpoint, 0, 500)
    if not cp then return end

    local exam = exams[source]
    if not exam or exam.type ~= "driving" then return end
    exam.checkpoint = cp
end)

RegisterNetEvent("dvm:cancelExam", function()
    local source = source
    exams[source] = nil
end)

MiscB.Cb("dvm:finishDrivingExam", function(source, clientViolations)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local exam = exams[source]
    if not exam or exam.type ~= "driving" then
        return { success = false, message = "Aucun examen en cours." }
    end
    exams[source] = nil

    local penalty = 0
    for i = 1, #exam.violations do
        penalty = penalty + (exam.violations[i].penalty or 5)
    end

    local score = 100 - penalty
    if score < 0 then score = 0 end

    local passScore = tonumber(generalCfg().DrivingPassingScore) or 85
    local passed = score >= passScore and #exam.violations < 5

    logAttempt(xPlayer, "driving", exam.licenseType, score, passed, false)

    if passed then
        grantLicense(xPlayer, exam.licenseType, score)
    end

    return {
        success = true,
        passed = passed,
        score = score,
        violations = exam.violations,
        violationCount = #exam.violations,
        passingScore = passScore,
        licenseType = exam.licenseType,
    }
end)

MiscB.Cb("dvm:attemptBribe", function(source, examType, licenseType, score, paymentMethod)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return { success = false } end

    local g = generalCfg()
    local bribe = type(g.BribeSystem) == "table" and g.BribeSystem or nil
    if not bribe or bribe.enabled ~= true then
        return { success = false, message = "Indisponible." }
    end

    local lType = MiscB.Str(licenseType, 32)
    if not lType or not licenseCfg(lType) then
        return { success = false, message = "Ce type de permis n'est pas valide." }
    end

    if hasLicense(xPlayer.identifier, lType) then
        return { success = false, message = "Vous possedez deja ce permis." }
    end

    local currentScore = MiscB.ToInt(score, 0, 100) or 0
    local minScore = tonumber(bribe.minScore) or 0
    if currentScore < minScore then
        return { success = false, message = "Votre score est trop faible." }
    end

    local amount = examType == "code" and (tonumber(bribe.codeExamBribe) or 2500) or (tonumber(bribe.drivingExamBribe) or 5000)
    if not charge(xPlayer, amount, paymentMethod, "dvm-pot-de-vin") then
        return { success = false, message = "Fonds insuffisants." }
    end

    local rate = tonumber(bribe.successRate) or 100
    local ok = math.random(100) <= rate

    if ok then
        if examType == "code" then
            MiscB.Insert([[
                INSERT INTO dvm_code_passed (identifier, license_type, score, created_at)
                VALUES (?, ?, ?, NOW())
            ]], { xPlayer.identifier, lType, currentScore })
        else
            grantLicense(xPlayer, lType, currentScore)
        end
    end

    logAttempt(xPlayer, examType == "code" and "code" or "driving", lType, currentScore, ok, true)

    return {
        success = ok,
        passed = ok,
        amount = amount,
        licenseType = lType,
        message = ok and "Le dossier a ete arrange." or "La tentative a echoue.",
    }
end)

RegisterNetEvent("dvm:editor:export", function(route)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.hasPermission("staff") and not xPlayer.hasPermission("admin") then return end
    if type(route) ~= "table" then return end

    local encoded = VFW.DB.Encode(route)
    console.info(("[dvm] export de parcours par %d :\n%s"):format(source, tostring(encoded)))

    TriggerClientEvent("dvm:editor:exportResult", source, { success = true, route = route, json = encoded })
end)

AddEventHandler("vfw:playerDropped", function(source)
    exams[source] = nil
end)
