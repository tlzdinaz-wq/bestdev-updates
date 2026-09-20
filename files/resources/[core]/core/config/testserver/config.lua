---@meta _
---@diagnostic disable: duplicate-doc-field

-- ============================================================
-- MODE SERVEUR DE TEST / DÉMO
-- ============================================================
-- Activez ce mode en ajoutant dans votre server.cfg :
--     set testserver "true"
-- (ou "false" pour un serveur de production normal)
--
-- Quand le mode est ACTIF :
--   1. Chaque joueur reçoit AUTOMATIQUEMENT toutes les permissions
--      du serveur dès le chargement de son personnage (octroi en
--      mémoire uniquement, AUCUNE écriture en base de données).
--   2. TOUTES les actions de SUPPRESSION persistantes et les BANS
--      sont neutralisés : impossible de supprimer un market, un item
--      boutique, un builder (props, coffres, motels, banques...),
--      de bannir un joueur, de wipe un joueur, etc.
--
-- Quand le mode est INACTIF (production) :
--   Le code s'auto-désactive entièrement : AUCUN comportement n'est
--   modifié et AUCUN wrapper n'est installé (zéro impact / zéro risque).
--
-- L'interrupteur principal est la convar lue côté serveur dans
-- testserver/server/guard.lua. Les options ci-dessous sont des
-- réglages fins facultatifs.
-- ============================================================

Config.TestServer = Config.TestServer or {}

-- Octroyer toutes les permissions aux joueurs (la plus grande permission).
Config.TestServer.GrantAllPermissions = true

-- Bloquer toutes les suppressions persistantes et les bans.
Config.TestServer.BlockDestructive = true

-- Niveau hiérarchique attribué aux joueurs en mode test (le plus haut
-- des rangs prédéfinis est 6 = « Niveau 5 / Gérant Staff »).
Config.TestServer.GrantLevel = 6
