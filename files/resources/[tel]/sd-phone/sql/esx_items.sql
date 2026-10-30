-- sd-phone : items du téléphone (téléphone noir `phone`, 7 couleurs, carte SIM).
--
-- UN SEUL FICHIER POUR TOUS LES SCHÉMAS. Il lit la table `items` de la base choisie et n'écrit que les
-- colonnes qu'elle possède :
--   * serveur VFW (cette base)  : name, label, type, weight, premium, perm, image, description, data
--   * ESX d'origine             : name, label, weight, rare, can_remove  (rare / can_remove gardent leur défaut)
--   * ancien ESX                : name, label, limit, rare, can_remove
-- Le fichier fourni avec sd-phone échouait ici avec « Unknown column 'rare' » ; celui-ci ne peut plus
-- échouer pour une colonne manquante.
--
-- COMMENT L'IMPORTER
--   1. Sélectionner la base du serveur (phpMyAdmin : cliquer sur son nom à gauche ; HeidiSQL / mysql :
--      `USE ma_base;` ou `mysql ma_base < esx_items.sql`).
--   2. Onglet « Importer » > choisir ce fichier > Exécuter. Aucune option à changer.
--   3. Un message « N item(s) ajouté(s) » s'affiche. Relancer le fichier est sans risque : une ligne
--      déjà présente n'est jamais modifiée (poids, image, libellé réglés dans Gestion restent intacts).
--
-- Ce fichier est OPTIONNEL : au premier démarrage, sd-phone crée lui-même ces lignes
-- (configs/phone.lua, SeedEsxItems = true). Il sert si vous préférez les poser à la main, ou avant de
-- démarrer sd-phone pour la première fois.
--
-- Poids : sur ce serveur 1 = 5 g (un téléphone = 40, une carte SIM = 2) ; sur ESX d'origine, 1.
-- Après l'import : redémarrer sd-phone, puis les joueurs déjà connectés se reconnectent pour recevoir le
-- catalogue. Les variantes se donnent avec /giveitem.

SET NAMES utf8mb4;

-- Colonnes de la table `items` de la base sélectionnée (NULL : la table n'existe pas ou aucune base choisie).
SET @cols := (
    SELECT GROUP_CONCAT(`COLUMN_NAME`)
    FROM `information_schema`.`COLUMNS`
    WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'items'
);

-- Schéma VFW : reconnu à ses colonnes `type` et `premium`.
SET @vfw := IFNULL(FIND_IN_SET('type', @cols) > 0 AND FIND_IN_SET('premium', @cols) > 0, 0);

SET @sql := IF(
    @cols IS NULL,
    'SELECT ''ERREUR : table items introuvable. Sélectionne d''''abord la base du serveur, puis relance l''''import.'' AS resultat',
    CONCAT(
        'INSERT IGNORE INTO `items` (`name`, `label`',
        IF(FIND_IN_SET('type', @cols), ', `type`', ''),
        IF(FIND_IN_SET('weight', @cols), ', `weight`', ''),
        IF(FIND_IN_SET('premium', @cols), ', `premium`', ''),
        IF(FIND_IN_SET('perm', @cols), ', `perm`', ''),
        IF(FIND_IN_SET('image', @cols), ', `image`', ''),
        IF(FIND_IN_SET('description', @cols), ', `description`', ''),
        IF(FIND_IN_SET('data', @cols), ', `data`', ''),
        ') SELECT v.`name`, v.`label`',
        IF(FIND_IN_SET('type', @cols), ', ''items''', ''),
        IF(FIND_IN_SET('weight', @cols), IF(@vfw, ', v.`weight_vfw`', ', v.`weight_esx`'), ''),
        IF(FIND_IN_SET('premium', @cols), ', 0', ''),
        IF(FIND_IN_SET('perm', @cols), ', ''0''', ''),
        IF(FIND_IN_SET('image', @cols), ', ''items/phone.webp''', ''),
        IF(FIND_IN_SET('description', @cols), ', v.`description`', ''),
        IF(FIND_IN_SET('data', @cols), ', ''{"type":"objects"}''', ''),
        ' FROM (',
        'SELECT ''phone'' AS `name`, ''Téléphone'' AS `label`, 40 AS `weight_vfw`, 1 AS `weight_esx`, ''Téléphone portable.'' AS `description`',
        ' UNION ALL SELECT ''phone_blue'', ''Téléphone bleu'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_green'', ''Téléphone vert'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_orange'', ''Téléphone orange'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_pink'', ''Téléphone rose'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_purple'', ''Téléphone violet'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_red'', ''Téléphone rouge'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''phone_yellow'', ''Téléphone jaune'', 40, 1, ''Téléphone portable.''',
        ' UNION ALL SELECT ''sim_card'', ''Carte SIM'', 2, 1, ''Carte SIM.''',
        ') v'
    )
);

PREPARE `phone_items` FROM @sql;
EXECUTE `phone_items`;
SET @ajoutes := ROW_COUNT();
DEALLOCATE PREPARE `phone_items`;

-- `phone` existe déjà sur ce serveur (téléphone noir) : il n'est donc pas recompté. `sim_card` ne sert que si
-- les téléphones uniques avec cartes SIM sont activés (configs/uniqueandsim.lua, Enabled = true).
SELECT IF(
    @cols IS NULL,
    'Rien importé : sélectionne d''abord la base du serveur.',
    CONCAT(@ajoutes, ' item(s) ajouté(s) à la table items. ', IF(@vfw, 'Schéma : serveur VFW.', 'Schéma : ESX.'))
) AS resultat;
