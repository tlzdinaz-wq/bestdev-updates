---@meta _
-- ============================================================
-- CONFIG - Logs Discord (Webhooks)
-- Remplissez les URLs de vos webhooks Discord ci-dessous.
-- Laissez une chaîne vide "" pour désactiver un canal.
-- ============================================================

logs = {}

logs.config = {
    general = {
        connect        = "",
        disconnect     = "",
        selectCharacter = "",
        armurerie      = "",
        killSuicide    = "",
        killPlayer     = "",
        facturation    = "",
        facturationreussie = "",
        facturationfail    = "",
        shooting       = ""
    },
    reports = {
        create  = "",
        take    = "",
        close   = "",
        update  = ""
    },
    society = {
        startService  = "",
        stopService   = "",
        startCraft    = "",
        finishCraft   = "",
        reset         = "",
        announce      = ""
    },
    banking = {
        deposit  = "",
        withdraw = ""
    },
    staff = {
        service     = "",
        blips       = "",
        wipe        = "",
        msg         = "",
        spect       = "",
        freeze      = "",
        kick        = "",
        jail        = "",
        unjail      = "",
        ban         = "",
        setjob      = "",
        setfaction  = "",
        car         = "",
        giveitem    = "",
        heal        = "",
        revive      = "",
        repair      = "",
        dv          = "",
        teleport    = "",
        setped      = "",
        unsetped    = "",
        upgrade     = "",
        setcarcolor = "",
        screen      = ""
    },
    inventory = {
        takeItem = {
            vehicle  = "",
            casier   = "",
            stockage = "",
            property = "",
            pickup   = ""
        },
        putItem = {
            vehicle  = "",
            casier   = "",
            stockage = "",
            property = "",
            pickup   = ""
        },
        giveItem    = "",
        giveMoney   = "",
        search = {
            search   = "",
            takeItem = ""
        },
        pickupItem  = ""
    },
    boutique = {
        vehicle = "",
        weapon  = "",
        pack    = ""
    },
    property = {
        all          = "",
        perquisition = ""
    },
    pdm = {
        vehiclePurchase = ""
    },
    crew = {
        addXp = ""
    },
    irs = {
        depot    = "",
        retrait  = "",
        transfer = ""
    },
    ac = {
        entityCreated  = "",
        entityCreating = "",
        explosion      = "",
        giveWeapon     = "",
        antiAttach     = ""
    }
}
