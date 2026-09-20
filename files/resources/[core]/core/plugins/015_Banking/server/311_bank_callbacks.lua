local Bank = VFW.Bank

local function registerCallback(name, handler)
    local ok, err = pcall(RegisterServerCallback, name, handler)
    if not ok then
        console.warn(("[%s] callback '%s' deja enregistre : %s"):format("Banking", name, tostring(err)))
        return false
    end
    return true
end


local function emptyAccount()
    return {
        iban = "",
        bank = 0,
        cash = 0,
        label = "",
        stats = {},
        transactions = {},
    }
end

local function normalizeAccountType(value)
    return tonumber(value) == 2 and 2 or 1
end

registerCallback("vfw:banking:getMyAccount", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return emptyAccount() end

    local iban = Bank.PlayerIban(xPlayer)

    return {
        iban = iban,
        bank = Bank.GetBank(xPlayer),
        label = xPlayer.name or "",
        cash = Bank.GetCash(xPlayer),
        stats = Bank.GetStats(iban),
        transactions = Bank.GetTransactions(iban),
    }
end)

registerCallback("vfw:banking:getMySocietyAccount", function(source)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return emptyAccount() end

    local jobName = Bank.SocietyJobName(xPlayer)
    if not jobName then return emptyAccount() end

    local iban = Bank.SocietyIban(jobName)
    if iban == "" then return emptyAccount() end

    return {
        iban = iban,
        bank = Bank.GetSocietyMoney(jobName),
        label = Bank.SocietyLabel(jobName),
        society = jobName,
        stats = Bank.GetStats(iban),
        transactions = Bank.GetTransactions(iban),
    }
end)

registerCallback("vfw:banking:withdraw", function(source, amount, accountType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    amount = Bank.Amount(amount)
    accountType = normalizeAccountType(accountType)

    if not amount then
        Bank.Notify(xPlayer, "ROUGE", "Ce montant n'est pas valide.")
        return false
    end

    if accountType == 2 then
        local jobName = Bank.SocietyJobName(xPlayer)
        if not jobName then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas d'entreprise.")
            return false
        end
        if not Bank.CanManageSociety(xPlayer, jobName) then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas acces au compte de l'entreprise.")
            return false
        end

        if not Bank.TakeSocietyMoney(jobName, amount) then
            Bank.Notify(xPlayer, "ROUGE", "Fonds insuffisants sur le compte de l'entreprise.")
            return false
        end

        if not Bank.GiveCash(xPlayer, amount) then
            Bank.AddSocietyMoney(jobName, amount)
            Bank.Notify(xPlayer, "ROUGE", "Impossible de recuperer l'argent liquide.")
            return false
        end

        Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
            ("Retrait especes - %s"):format(xPlayer.name or ""), "withdraw", amount, false, true)

        Bank.Log("banking.withdraw", "Retrait entreprise",
            ("%s\nEntreprise : `%s`\nMontant : `%d`"):format(VFW.Logs.Describe(source), jobName, amount))

        Bank.Notify(xPlayer, "VERT", ("Vous avez retire %d$ du compte de l'entreprise."):format(amount))
        return true
    end

    local balance = Bank.GetBank(xPlayer)
    if balance < amount then
        Bank.Notify(xPlayer, "ROUGE", "Fonds insuffisants sur votre compte.")
        return false
    end

    xPlayer.removeAccountMoney("bank", amount, "banking:withdraw")

    if not Bank.GiveCash(xPlayer, amount) then
        xPlayer.addAccountMoney("bank", amount, "banking:withdraw-rollback")
        Bank.Notify(xPlayer, "ROUGE", "Impossible de recuperer l'argent liquide.")
        return false
    end

    Bank.AddTransaction(Bank.PlayerIban(xPlayer), 1, "Retrait especes", "withdraw", amount, false, true)

    Bank.Log("banking.withdraw", "Retrait bancaire",
        ("%s\nMontant : `%d`"):format(VFW.Logs.Describe(source), amount))

    Bank.Notify(xPlayer, "VERT", ("Vous avez retire %d$."):format(amount))
    return true
end)

registerCallback("vfw:banking:deposit", function(source, amount, accountType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    amount = Bank.Amount(amount)
    accountType = normalizeAccountType(accountType)

    if not amount then
        Bank.Notify(xPlayer, "ROUGE", "Ce montant n'est pas valide.")
        return false
    end

    if Bank.GetCash(xPlayer) < amount then
        Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas assez d'argent liquide.")
        return false
    end

    if accountType == 2 then
        local jobName = Bank.SocietyJobName(xPlayer)
        if not jobName then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas d'entreprise.")
            return false
        end
        if not Bank.CanManageSociety(xPlayer, jobName) then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas acces au compte de l'entreprise.")
            return false
        end

        if not Bank.TakeCash(xPlayer, amount) then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas assez d'argent liquide.")
            return false
        end

        Bank.AddSocietyMoney(jobName, amount)

        Bank.AddTransaction(Bank.SocietyIban(jobName), 2,
            ("Depot especes - %s"):format(xPlayer.name or ""), "deposit", amount, true, true)

        Bank.Log("banking.deposit", "Depot entreprise",
            ("%s\nEntreprise : `%s`\nMontant : `%d`"):format(VFW.Logs.Describe(source), jobName, amount))

        Bank.Notify(xPlayer, "VERT", ("Vous avez depose %d$ sur le compte de l'entreprise."):format(amount))
        return true
    end

    if not Bank.TakeCash(xPlayer, amount) then
        Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas assez d'argent liquide.")
        return false
    end

    xPlayer.addAccountMoney("bank", amount, "banking:deposit")

    Bank.AddTransaction(Bank.PlayerIban(xPlayer), 1, "Depot especes", "deposit", amount, true, true)

    Bank.Log("banking.deposit", "Depot bancaire",
        ("%s\nMontant : `%d`"):format(VFW.Logs.Describe(source), amount))

    Bank.Notify(xPlayer, "VERT", ("Vous avez depose %d$."):format(amount))
    return true
end)

registerCallback("vfw:banking:transfer", function(source, amount, targetIban, accountType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return false end

    amount = Bank.Amount(amount)
    accountType = normalizeAccountType(accountType)

    if not amount then
        Bank.Notify(xPlayer, "ROUGE", "Ce montant n'est pas valide.")
        return false
    end

    if type(targetIban) ~= "string" then
        Bank.Notify(xPlayer, "ROUGE", "Cet IBAN n'est pas valide.")
        return false
    end

    targetIban = targetIban:gsub("%D", "")
    if #targetIban ~= 8 then
        Bank.Notify(xPlayer, "ROUGE", "L'IBAN doit contenir 8 chiffres.")
        return false
    end

    local target = Bank.ResolveIban(targetIban)
    if not target then
        Bank.Notify(xPlayer, "ROUGE", "Ce compte n'existe pas.")
        return false
    end

    local sourceIban, sourceLabel, jobName

    if accountType == 2 then
        jobName = Bank.SocietyJobName(xPlayer)
        if not jobName then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas d'entreprise.")
            return false
        end
        if not Bank.CanManageSociety(xPlayer, jobName) then
            Bank.Notify(xPlayer, "ROUGE", "Vous n'avez pas acces au compte de l'entreprise.")
            return false
        end
        sourceIban = Bank.SocietyIban(jobName)
        sourceLabel = Bank.SocietyLabel(jobName)
    else
        sourceIban = Bank.PlayerIban(xPlayer)
        sourceLabel = xPlayer.name or ""
    end

    if sourceIban == "" or sourceIban == target.iban then
        Bank.Notify(xPlayer, "ROUGE", "Virement impossible vers ce compte.")
        return false
    end

    if accountType == 2 then
        if not Bank.TakeSocietyMoney(jobName, amount) then
            Bank.Notify(xPlayer, "ROUGE", "Fonds insuffisants sur le compte de l'entreprise.")
            return false
        end
    else
        if Bank.GetBank(xPlayer) < amount then
            Bank.Notify(xPlayer, "ROUGE", "Fonds insuffisants sur votre compte.")
            return false
        end
        xPlayer.removeAccountMoney("bank", amount, "banking:transfer")
    end

    local credited = false

    if target.type == "society" then
        Bank.AddSocietyMoney(target.key, amount)
        credited = true
    else
        credited = Bank.CreditIdentifier(target.key, amount, "banking:transfer")
    end

    if not credited then
        if accountType == 2 then
            Bank.AddSocietyMoney(jobName, amount)
        else
            xPlayer.addAccountMoney("bank", amount, "banking:transfer-rollback")
        end
        Bank.Notify(xPlayer, "ROUGE", "Le compte destinataire est introuvable.")
        return false
    end

    local targetLabel = target.label ~= "" and target.label or target.iban

    Bank.AddTransaction(sourceIban, accountType,
        ("Virement vers %s"):format(targetLabel), "transfer", amount, false, true)
    Bank.AddTransaction(target.iban, target.type == "society" and 2 or 1,
        ("Virement de %s"):format(sourceLabel), "transfer", amount, true, true)

    if target.type == "player" then
        local receiver = VFW.GetPlayerFromIdentifier(target.key)
        if receiver then
            Bank.Notify(receiver, "VERT", ("Vous avez recu un virement de %d$ de %s."):format(amount, sourceLabel))
        end
    end

    Bank.Log("irs.transfer", "Virement",
        ("%s\nDe : `%s`\nVers : `%s`\nMontant : `%d`"):format(
            VFW.Logs.Describe(source), sourceIban, target.iban, amount))

    Bank.Notify(xPlayer, "VERT", ("Virement de %d$ effectue."):format(amount))
    return true
end)
