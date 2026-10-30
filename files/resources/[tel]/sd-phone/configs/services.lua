-- Services app. Maps framework JOBS to "companies" the phone surfaces: a public directory
-- (locate / call / message) plus boss management of the company's shared balance and employee
-- roster. Society money + employee reads route through bridge/server/society.lua (adapts
-- qb-banking / Renewed-Banking / qbx_management / qb-management / esx_addonaccount).
return {
    -- ESX-ONLY fallback. On QBCore/QBox boss status is read from the grade's
    -- `isboss` flag and this is ignored. On ESX (no isboss flag) it's the minimum
    -- grade treated as a boss when a company has no own `bossGrade`.
    DefaultBossGrade = 3,

    -- Job a fired employee is reset to (QBCore/QBox and ESX both use 'unemployed').
    UnemployedJob = 'unemployed',

    -- Cap on how many employees the roster returns.
    EmployeeLimit = 100,

    -- Jobs tab (multi-job). Only active on QBCore/QBox; the tab is hidden on ESX.
    -- Max jobs a player can keep saved at once. Set to 0 to disable the cap
    -- (unlimited saved jobs) - this also hides the X/X capacity bar in the app.
    MaxSavedJobs = 5,
    -- Jobs never listed, switchable, or accept-able from the Jobs tab (resign to
    -- unemployed via the Actions tab's Quit instead).
    JobBlacklist = { 'unemployed' },
    -- Drop the player off duty when they switch active job (mirrors sd-multijob).
    SwitchOffDuty = true,

    -- Business invoicing. On-duty employees send a banking invoice from their
    -- business to another player; the target pays it from the Banking app and
    -- the sender is notified. Only active on QBCore/QBox (on-duty state must be
    -- resolvable); the section is hidden on ESX, like the Jobs tab.
    -- Payout: when a society bank is available the payment is credited to the
    -- business account; otherwise it falls back to the sending employee's own
    -- bank (see bridge/server/society.lua). A per-company `commission` (below)
    -- splits off a cut of the society-credited payment to the sending employee.
    -- Off on this server: invoicing here is bound to the multi-job model, which VFW does not use,
    -- and VFW already has its own billing (billing_invoices / society_billings).
    InvoicesEnabled = false,
    -- Smallest and largest amount a single invoice may be for.
    MinInvoiceAmount = 1,
    MaxInvoiceAmount = 1000000,

    -- VFW only: every job of the server - the ones already there and those made later in Gestion
    -- (the society builder, core:create:society) - is added to the directory by itself, with the logo,
    -- address and map position set in Gestion when there are any, and follows every later edit or
    -- deletion, no restart needed. The entries in `Companies` below take priority
    -- for the same job (that is where phone lines such as 911 live); a logo set in Gestion is
    -- still added to them. See server/vfwcompanies.lua.
    Auto = {
        Enabled = true,
        -- Jobs never listed in the directory. `other` ("Divers") is a catch-all, not a business.
        ExcludeJobs = { 'other' },
        -- Society types never listed (the `type` chosen in the builder, e.g. 'farm').
        ExcludeTypes = {},
        -- Badge used when a company has no logo, by society type; `Default` covers the rest. The
        -- colour is only a fallback: the accent chosen in the builder wins when there is one.
        Default = { emoji = '🏢', color = '#5E5CE6' },
        Types = {
            police    = { emoji = '🚓', color = '#0A84FF' },
            ambulance = { emoji = '🚑', color = '#C0392B' },
            mechanic  = { emoji = '⚙️', color = '#3A3A3C' },
            concess   = { emoji = '🚗', color = '#F39C12' },
            dynasty   = { emoji = '🏠', color = '#8E44AD' },
            farm      = { emoji = '🍽️', color = '#E67E22' },
            taxi      = { emoji = '🚕', color = '#27AE60' },
            milice    = { emoji = '🛡️', color = '#4B5320' },
        },
    },

    -- One entry per company. `job` is the framework job name (the key everything
    -- keys off). `coords` powers the client-side "Locate" waypoint. Listing a job
    -- here adds it to the public directory and enables Job Calls / company
    -- messaging; jobs NOT listed here still get the rest of the Actions tab (duty,
    -- bank, employees, quit) - they just won't appear in the directory.
    -- `canCall` + `callNumber` give the company a phone line. It is dialable two
    -- ways: the Call button in the Services app, and typing the number into the
    -- Phone dialer, so 911 rings every on-duty officer exactly as the button does.
    -- Either way it rings all on-duty employees who have Job Calls switched on,
    -- and the first to answer takes it. Give any company a number to make it
    -- reachable; leave canCall false and it stays directory-only.
    -- `bossGrade` is an ESX-ONLY fallback (overrides DefaultBossGrade for this
    -- company); QBCore/QBox ignore it and use the grade's isboss flag.
    -- `commission` is an OPTIONAL fraction 0.0-1.0 of a paid business invoice
    -- that goes to the sending employee, with the remainder going to the society
    -- account (the two always sum to the invoice amount, so no money is minted).
    -- Absent or 0 means the whole amount goes to the society. Only applies when a
    -- society bank is available; the no-society fallback already pays the sending
    -- employee in full, so no commission is split there.
    Companies = {
        -- The jobs below are this server's own (jobs table). On VFW every grade carries a real boss
        -- flag, so the ESX-only bossGrade fallback is not read and is left out.
        {
            job = 'police',
            label = 'SASP Sud',
            location = 'Mission Row',
            color = '#0A84FF',
            emoji = '🚓',
            canCall = true,
            callNumber = '911',
            coords = { x = 425.1, y = -979.5, z = 30.7 },
        },
        {
            job = 'sheriff',
            label = 'SASP Nord',
            location = 'Paleto Bay',
            color = '#1D4E89',
            emoji = '🚔',
            canCall = true,
            callNumber = '913',
            coords = { x = -448.3, y = 6011.7, z = 31.7 },
        },
        {
            job = 'ambulance',
            label = 'EMS',
            location = 'Pillbox',
            color = '#C0392B',
            emoji = '🚑',
            canCall = true,
            callNumber = '912',
            coords = { x = 307.7, y = -1433.4, z = 29.9 },
        },
        {
            job = 'mechanic',
            label = 'Mécanicien',
            location = 'LS Customs',
            color = '#3A3A3C',
            emoji = '⚙️',
            canCall = false,
            commission = 0.1,
            coords = { x = -347.3, y = -133.8, z = 39.0 },
        },
        {
            job = 'concess',
            label = 'Concessionnaire',
            location = 'Premium Deluxe Motorsport',
            color = '#F39C12',
            emoji = '🚗',
            canCall = false,
            commission = 0.1,
            coords = { x = -33.0, y = -1102.0, z = 26.4 },
        },
        {
            job = 'dynasty',
            label = 'Dynasty 8',
            location = 'Agence immobilière',
            color = '#8E44AD',
            emoji = '🏠',
            canCall = false,
            commission = 0.1,
            coords = { x = -706.9, y = 267.9, z = 83.1 },
        },
    },
}
