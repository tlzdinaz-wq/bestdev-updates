-- ============================================================================
-- AntiAttach — Config (exploit "parachute launch", issue CFX #4030)
-- ----------------------------------------------------------------------------
-- Un cheater spawn un objet parachute et l'attache à un joueur pour le
-- propulser violemment en l'air. Le mouvement anormal est ensuite flag par
-- l'anticheat mouvement (WaveShield) → la VICTIME innocente est bannie.
--
-- Ce module renverse la situation : il protège la victime (détache l'objet +
-- annule la vélocité) puis remonte le VRAI cheater (premier propriétaire réseau
-- de l'objet) au serveur, qui le sanctionne.
--
-- Adapté pour EVE (framework VFW). Config 100% autonome : ne dépend
-- d'aucune autre resource.
-- ============================================================================

AntiAttachConfig = {
    enabled = true,

    -- IMPORTANT (gros serveur) : la détection temps-réel repose sur
    -- `entityCreated` (réactif, quasi-gratuit). Les deux boucles ci-dessous ne
    -- sont que des filets de sécurité, donc on dissocie :
    --   • selfCheckIntervalMs : auto-protection (≈4 natives) → fréquent, cheap.
    --   • poolScanIntervalMs  : balayage GetGamePool('CObject') (coûteux en zone
    --     dense) → espacé pour ne pas peser sur chacun des clients en permanence.
    selfCheckIntervalMs = 200,   -- vérif "mon ped est-il attaché à un objet blacklisté ?"
    poolScanIntervalMs  = 2000,  -- balayage complet du pool d'objets (filet de sécurité)
    watchDurationMs     = 3000,  -- durée de surveillance rapprochée d'un objet fraîchement créé
    maxWatchers         = 16,    -- nb max de surveillances rapprochées simultanées (anti-DoS spam d'objets)
    detachSelf          = true,  -- détache immédiatement le ped local propulsé
    deleteObject        = true,  -- supprime l'objet malveillant (si contrôle réseau obtenu)
    reportAttacker      = true,  -- signale le propriétaire de l'objet au serveur
    reportCooldownMs    = 4000,  -- anti-spam des reports côté client (par objet)

    -- Modèles d'objets JAMAIS légitimes attachés à un joueur. GetHashKey couvre
    -- les variantes ; on stocke aussi le hash brut unsigned côté runtime.
    blacklistedModels = {
        1336576410,                       -- p_parachute1_mp_s (hash brut signalé dans l'issue #4030)
        GetHashKey('p_parachute1_mp_s'),
        GetHashKey('p_parachute1_s'),
        GetHashKey('p_parachute1_sp_s'),
        GetHashKey('p_parachute_s'),
    },

    -- ─── Sanction côté serveur ───────────────────────────────────────────────
    serverBan = {
        banAttacker      = true,     -- bannir le propriétaire de l'objet
        minUniqueVictims = 1,        -- nb de victimes distinctes avant ban (augmenter pour durcir l'anti-abus)
        reportWindowMs   = 20000,    -- fenêtre de corrélation des reports
        rateLimitMs      = 3000,     -- anti-spam par couple victime→attaquant

        -- Anti-framing : l'attache d'objet exige la proximité réseau. On refuse
        -- de bannir si l'« attaquant » signalé n'est pas physiquement proche de
        -- la victime. 0.0 = désactive le contrôle de distance.
        maxAttackDistance = 350.0,

        -- Raison affichée au joueur banni + enregistrée en base.
        banReason = "EVE AC | Exploit d'attache d'objet (propulsion joueur) - #4030",

        -- Permissions VFW protégées : un joueur possédant l'une d'elles ne sera
        -- JAMAIS banni par ce module (staff / dev). Voir playerGlobal.permissions.
        bypassPermissions = {
            "dev",
            "staff_menu",
            "ban",
        },

        -- Webhook Discord dédié (optionnel). Vide = pas d'embed dédié ; le log
        -- passe de toute façon par VFW.SendAntiCheat (panel) + logs.ac.antiAttach.
        webhook = "",
    },
}
