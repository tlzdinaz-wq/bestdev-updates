local Cl = VFW.Cloths

VFW.Identity = VFW.Identity or {}

local Id = VFW.Identity

local CARD_ITEM = "carte_identite"
local SHOW_DISTANCE = 5.0
local KEEP_DISTANCE = 3.5

local DOC_TYPES = {
    identity = "identity",
    driver = "driver",
    motorbike = "motorbike",
    truck = "truck",
    weapon = "weapon",
    weapon_leger = "weapon",
    weapon_lourd = "weapon",
    job = "job",
    cayo_visa = "cayo_visa",
}

local LICENSE_FOR_DOC = {
    driver = "dmvschool",
    motorbike = "motorbike",
    truck = "truck",
    weapon = "ppa_leger",
    weapon_leger = "ppa_leger",
    weapon_lourd = "ppa_lourd",
    cayo_visa = "cayo_visa",
}

local CATEGORY_FOR_DOC = {
    driver = "B",
    motorbike = "A",
    truck = "C",
}

local function today()
    return os.date("%d/%m/%Y")
end

local function addYears(years)
    return os.date("%d/%m/%Y", os.time() + (years * 365 * 24 * 3600))
end

local function documents(xPlayer)
    local meta = xPlayer.getMeta("documents")
    if type(meta) ~= "table" then
        meta = {}
    end
    return meta
end

local function documentDates(xPlayer, docType)
    local meta = documents(xPlayer)
    local entry = meta[docType]

    if type(entry) ~= "table" or type(entry.issued) ~= "string" then
        entry = { issued = today(), expires = addYears(10) }
        meta[docType] = entry
        xPlayer.setMeta("documents", meta)
    end

    return entry
end

local function hasLicense(xPlayer, name)
    if not name then return true end

    local licenses = xPlayer.licenses
    if type(licenses) ~= "table" then return false end

    if licenses[name] ~= nil then
        return licenses[name] and true or false
    end

    for i = 1, #licenses do
        local entry = licenses[i]
        if type(entry) == "table" and entry.type == name then
            return true
        end
    end

    return false
end

function Id.BuildCard(xPlayer, docType)
    local card = DOC_TYPES[docType] or "identity"

    local data = {
        type = card,
        lastName = xPlayer.lastName,
        firstName = xPlayer.firstName,
        date_of_birth = xPlayer.dateofbirth,
        sex = (Cl.NormalizeGender(xPlayer.sex) == "Femme") and "Femme" or "Homme",
        height = xPlayer.height,
        address = (xPlayer.address ~= nil and xPlayer.address ~= "") and xPlayer.address or "Non renseignee",
        photo = xPlayer.mugshot,
        job_label = xPlayer.job and xPlayer.job.label or "Sans emploi",
        job_grade_label = xPlayer.job and xPlayer.job.grade_label or "",
    }

    if card == "driver" or card == "motorbike" or card == "truck" then
        local dates = documentDates(xPlayer, docType)
        data.category = CATEGORY_FOR_DOC[docType] or "B"
        data.issued_date = dates.issued
        data.expiry_date = dates.expires
    elseif card == "weapon" then
        local dates = documentDates(xPlayer, docType)
        data.issued_date = dates.issued
        data.expiry_date = dates.expires
        data.number = ("PPA-%06d"):format(tonumber(xPlayer.charId) or 0)
    elseif card == "cayo_visa" then
        local dates = documentDates(xPlayer, "cayo_visa")
        data.issued_date = dates.issued
        data.expires_date = dates.expires
        data.visa_number = ("CAYO-%05d"):format(tonumber(xPlayer.charId) or 0)
        data.issuer = "Gouvernement de Cayo"
        data.visa_expired = not hasLicense(xPlayer, "cayo_visa")
    end

    return data
end

RegisterServerCallback("identity:getData", function(source, serverId, docType)
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return nil end

    local target = xPlayer
    local wanted = Cl.Int(serverId, source)

    if wanted ~= source then
        local other = VFW.GetPlayerFromId(wanted)
        if not other then return nil end

        local a, b = Cl.Coords(source), Cl.Coords(wanted)
        if not a or not b or Cl.Distance(a, b) > SHOW_DISTANCE then return nil end

        target = other
    end

    local kind = type(docType) == "string" and docType or "identity"
    if not DOC_TYPES[kind] then kind = "identity" end

    return Id.BuildCard(target, kind)
end)

RegisterNetEvent("core:identity:display", function(targetServerId, docType)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local targetId = Cl.Int(targetServerId, nil)
    if not targetId or targetId == source then return end

    local target = VFW.GetPlayerFromId(targetId)
    if not target then return end

    if not Cl.RateLimit(source, "identitydisplay", 1000) then return end

    local kind = type(docType) == "string" and docType or "identity"
    if not DOC_TYPES[kind] then return end

    local license = LICENSE_FOR_DOC[kind]
    if license and not hasLicense(xPlayer, license) then
        Cl.Notify(source, "Vous ne possedez pas ce document.")
        return
    end

    local a, b = Cl.Coords(source), Cl.Coords(targetId)
    if not a or not b or Cl.Distance(a, b) > SHOW_DISTANCE then
        Cl.Notify(source, "Vous etes trop loin de cette personne.")
        return
    end

    TriggerClientEvent("core:identity:show", targetId, Id.BuildCard(xPlayer, kind))

    CreateThread(function()
        local elapsed = 0
        while elapsed < 15000 do
            Wait(500)
            elapsed = elapsed + 500

            local holder = VFW.GetPlayerFromId(source)
            local viewer = VFW.GetPlayerFromId(targetId)
            if not holder or not viewer then break end

            local ca, cb = Cl.Coords(source), Cl.Coords(targetId)
            if not ca or not cb or Cl.Distance(ca, cb) > KEEP_DISTANCE then
                TriggerClientEvent("vfw:identity:forceCloseDocument", targetId)
                return
            end
        end

        TriggerClientEvent("vfw:identity:forceCloseDocument", targetId)
    end)
end)

RegisterNetEvent("vfw:identity:closeDocument", function(targetServerId)
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end

    local targetId = Cl.Int(targetServerId, nil)
    if not targetId or targetId == source then return end
    if not VFW.GetPlayerFromId(targetId) then return end

    TriggerClientEvent("vfw:identity:forceCloseDocument", targetId)
end)

RegisterNetEvent("identity:givemycard", function()
    local source = source
    local xPlayer = VFW.GetPlayerFromId(source)
    if not xPlayer then return end
    if not Cl.RateLimit(source, "givemycard", 5000) then return end

    local cfg = IdentityConfig and IdentityConfig.IdentityCardNpc
    if not cfg or cfg.enabled == false then return end

    local coords = Cl.Coords(source)
    if not coords then return end

    local positions = cfg.positions or {}
    local near = false
    for i = 1, #positions do
        if Cl.Distance(coords, positions[i]) <= 5.0 then
            near = true
            break
        end
    end

    if not near then return end

    if Cl.CountItem(xPlayer, CARD_ITEM) > 0 then
        Cl.Notify(source, "Vous possedez deja votre carte d'identite.")
        return
    end

    local meta = {
        firstname = xPlayer.firstName,
        lastname = xPlayer.lastName,
        dateofbirth = xPlayer.dateofbirth,
        sex = xPlayer.sex,
        height = xPlayer.height,
        charId = xPlayer.charId,
        renamed = ("CNI %s %s"):format(xPlayer.firstName or "", xPlayer.lastName or ""),
    }

    if Cl.GiveItem(xPlayer, CARD_ITEM, 1, meta) then
        Cl.Notify(source, "Votre carte d'identite vous a ete remise.", "VERT")
    else
        Cl.Notify(source, "Inventaire plein.")
    end
end)

Cl.WaitInventory(function(Inv)
    Inv.RegisterUsableItem(CARD_ITEM, function(xPlayer)
        local source = xPlayer.source
        if not Cl.RateLimit(source, "opencard", 1500) then return end
        TriggerClientEvent("identity:opencard", source, "identity")
    end)
end)

VFW.RegisterCommand("carteidentite", nil, function(source, xPlayer)
    TriggerClientEvent("identity:viewOwnCard", source, "identity")
end, {
    help = "Consulter sa carte d'identite",
})
