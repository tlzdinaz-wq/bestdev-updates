-- Animations du personnage affiché à l'écran de sélection.
--
-- Le clone du personnage survolé salue à son arrivée, puis enchaîne des poses d'attente différentes entrecoupées
-- de gestes (salut militaire, signe de paix, applaudissements...), choisies selon son sexe. Pour qu'il ne refasse
-- jamais la même chose :
--   · les animations sont tirées dans un PAQUET MÉLANGÉ : tout le paquet passe avant que la première revienne ;
--   · le paquet est partagé entre les personnages : changer de personnage n'en recommence pas un (le salut
--     n'est donc plus toujours le même) ;
--   · une animation qui ne se lance pas (nom absent du jeu) est écartée pour la session.
-- Tout se règle dans Config.Multicharacter.Animations (config/multicharacter/config.lua).
--
-- Le clone est figé sur place (FreezeEntityPosition) : les animations jouées sur place continuent de tourner.

CloneAnimations = {}

local function clip(dict, anim) return { dict = dict, anim = anim } end

--- Plusieurs clips d'un même dictionnaire (idle_a, idle_b, idle_c...).
local function clips(dict, ...)
    local out = {}
    for _, anim in ipairs({ ... }) do out[#out + 1] = clip(dict, anim) end
    return out
end

local function merge(...)
    local out = {}
    for _, list in ipairs({ ... }) do
        for i = 1, #list do out[#out + 1] = list[i] end
    end
    return out
end

local function celebrations(prefix, ...)
    local out = {}
    for _, name in ipairs({ ... }) do
        out[#out + 1] = clip(("anim@mp_player_intcelebration%s@%s"):format(prefix, name), name)
    end
    return out
end

local DEFAULTS <const> = {
    Enabled = true,
    Greeting = true,              -- un geste à l'apparition du personnage (tiré au hasard dans « Gestures »)
    Interval = { 6000, 10000 },   -- durée (ms) d'une pose d'attente avant la suivante
    GestureChance = 55,           -- % de chances d'un geste entre deux poses
    Idles = {
        male = merge(
            clips("anim@mp_corona_idles@male_c@idle_a", "idle_a"),
            clips("amb@world_human_hang_out_street@male_a@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_hang_out_street@male_b@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_hang_out_street@male_c@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_stand_impatient@male@no_sign@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_muscle_flex@arms_at_side@idle_a", "idle_a", "idle_b", "idle_c")
        ),
        female = merge(
            clips("anim@mp_corona_idles@female_b@idle_a", "idle_a"),
            clips("anim@mp_corona_idles@female_c@idle_a", "idle_a"),
            clips("amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_hang_out_street@female_hold_arm@idle_a", "idle_a", "idle_b", "idle_c"),
            clips("amb@world_human_stand_impatient@female@no_sign@idle_a", "idle_a", "idle_b", "idle_c")
        ),
    },
    Gestures = {
        male = celebrations("male", "wave", "salute", "peace", "thumbs_up", "blow_kiss", "slow_clap", "jazz_hands",
            "face_palm", "no_way", "shadow_boxing", "knuckle_crunch"),
        female = celebrations("female", "wave", "salute", "peace", "thumbs_up", "blow_kiss", "slow_clap", "jazz_hands",
            "face_palm", "no_way", "shadow_boxing", "knuckle_crunch"),
    },
}

--- Réglages : les valeurs d'origine, remplacées clef par clef par Config.Multicharacter.Animations.
local function settings()
    local custom = Config and Config.Multicharacter and Config.Multicharacter.Animations
    if type(custom) ~= "table" then return DEFAULTS end

    local out = {}
    for key, value in pairs(DEFAULTS) do out[key] = value end
    for key, value in pairs(custom) do out[key] = value end
    return out
end

-- ── paquets mélangés (partagés entre les personnages) ──

local decks = {}   -- clef (« idle:male »...) -> { cards = { ... }, last = animation }
local unusable = {} -- animation -> true : ne se lance pas, écartée pour la session

local function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

--- Tire l'animation suivante : tout le paquet passe avant qu'une carte revienne, et jamais deux fois la même de suite.
local function draw(key, list)
    for _ = 1, #list + 1 do
        local deck = decks[key]
        if not deck or #deck.cards == 0 then
            local cards = {}
            for i = 1, #list do
                if not unusable[list[i]] then cards[#cards + 1] = list[i] end
            end
            if #cards == 0 then return nil end
            shuffle(cards)
            -- la carte du dessus (fin de liste) ne doit pas être celle qui vient de passer
            if #cards > 1 and deck and cards[#cards] == deck.last then
                cards[#cards], cards[1] = cards[1], cards[#cards]
            end
            deck = { cards = cards, last = deck and deck.last }
            decks[key] = deck
        end

        local card = table.remove(deck.cards)
        deck.last = card
        if not unusable[card] then return card end
    end
    return nil
end

--- Charge un dictionnaire d'animations (1,5 s au plus). Faux s'il n'existe pas.
local function load(dict)
    if type(dict) ~= "string" then return false end
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

--- Lance les animations du clone. `alive()` rend faux dès que le clone n'est plus celui affiché : la boucle s'arrête.
---@param clone number
---@param alive fun(): boolean
function CloneAnimations.Start(clone, alive)
    local cfg = settings()
    if cfg.Enabled == false then return end

    CreateThread(function()
        local sex = GetEntityModel(clone) == joaat("mp_f_freemode_01") and "female" or "male"
        local idles = (cfg.Idles or {})[sex] or {}
        local gestures = (cfg.Gestures or {})[sex] or {}

        -- Attend `ms` par petits pas pour s'arrêter dès que le clone est remplacé. Faux si le clone a disparu.
        local function sleep(ms)
            local deadline = GetGameTimer() + ms
            while GetGameTimer() < deadline do
                if not alive() then return false end
                Wait(100)
            end
            return alive()
        end

        --- Joue une animation et vérifie qu'elle tourne vraiment ; sinon elle est écartée.
        local function play(entry, loop)
            if not alive() then return false end
            if not load(entry.dict) or not alive() then
                unusable[entry] = true
                return false
            end
            TaskPlayAnim(clone, entry.dict, entry.anim, 3.0, -3.0, -1, loop and 1 or 0, 0.0, false, false, false)

            for _ = 1, 5 do
                Wait(100)
                if not alive() then return false end
                if IsEntityPlayingAnim(clone, entry.dict, entry.anim, 3) then return true end
            end
            unusable[entry] = true
            return false
        end

        local function duration(entry)
            local seconds = tonumber(GetAnimDuration(entry.dict, entry.anim)) or 2.0
            return math.max(800, math.min(5000, math.floor(seconds * 1000)))
        end

        --- Un geste tiré au hasard, joué une fois. Faux si le clone a disparu.
        local function gesture()
            if #gestures == 0 then return true end
            for _ = 1, 4 do
                local entry = draw("gesture:" .. sex, gestures)
                if not entry then return true end
                if play(entry, false) then return sleep(duration(entry)) end
                if not alive() then return false end
            end
            return true
        end

        if cfg.Greeting and not gesture() then return end

        local interval = cfg.Interval or DEFAULTS.Interval
        local minWait = math.min(interval[1], interval[2])
        local maxWait = math.max(interval[1], interval[2])
        local failures = 0
        while alive() do
            local idle = draw("idle:" .. sex, idles)
            if not idle then return end

            if play(idle, true) then
                failures = 0
                if not sleep(math.random(minWait, maxWait)) then return end

                if math.random(100) <= (tonumber(cfg.GestureChance) or 0) and not gesture() then return end
            else
                -- Animation absente : on en tire une autre, sans tourner à vide si plusieurs échouent d'affilée.
                failures = failures + 1
                if failures >= 12 or not alive() then return end
            end
        end
    end)
end

-- Utilisé par les tests ; sans effet en jeu.
CloneAnimations._reset = function()
    decks = {}
    unusable = {}
end
