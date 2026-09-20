-- =====================================================================
--  AVREX / EVE — Schéma complet de la base de données
--  Framework : core (VFW) v1.12.9  —  MySQL 8 / MariaDB 10.5+
--
--  Reconstruit intégralement à partir des requêtes SQL présentes dans
--  resources/[core]/core (modules, plugins, jobs) et ox_doorlock.
--
--  Nom de la base : `avrex`
--  Import :   mysql -u root -p < avrex.sql
--             (crée la base `avrex` si elle n'existe pas, puis l'utilise)
--  Toutes les tables sont créées en IF NOT EXISTS : le fichier est
--  rejouable sur une base existante sans perte de données.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `avrex`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `avrex`;

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

-- =====================================================================
--  1. COMPTES & PERSONNAGES
-- =====================================================================

CREATE TABLE IF NOT EXISTS `users` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  NOT NULL,
  `uuid`        VARCHAR(64)  DEFAULT NULL,
  `name`        VARCHAR(100) DEFAULT NULL,
  `role`        VARCHAR(32)  NOT NULL DEFAULT 'user',
  `permissions` LONGTEXT     DEFAULT NULL,
  `slots`       TINYINT(4)   NOT NULL DEFAULT 2,
  `playtime`    BIGINT(20)   NOT NULL DEFAULT 0,
  `spacecoins`  INT(11)      NOT NULL DEFAULT 0,
  `vip_tier`    TINYINT(4)   NOT NULL DEFAULT 0,
  `banned`      TINYINT(1)   NOT NULL DEFAULT 0,
  `last_seen`   DATETIME     DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_users_identifier` (`identifier`),
  UNIQUE KEY `uk_users_uuid` (`uuid`),
  KEY `idx_users_role` (`role`),
  KEY `idx_users_last_seen` (`last_seen`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `characters` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  NOT NULL,
  `account_id`  INT(11)      NOT NULL,
  `char_slot`   TINYINT(4)   NOT NULL DEFAULT 1,
  `firstname`   VARCHAR(50)  NOT NULL DEFAULT '',
  `lastname`    VARCHAR(50)  NOT NULL DEFAULT '',
  `dateofbirth` VARCHAR(25)  DEFAULT NULL,
  `sex`         VARCHAR(10)  DEFAULT 'm',
  `birthplace`  VARCHAR(100) DEFAULT NULL,
  `height`      INT(11)      DEFAULT 180,
  `skin`        LONGTEXT     DEFAULT NULL,
  `tattoos`     LONGTEXT     DEFAULT NULL,
  `mugshot`     VARCHAR(512) DEFAULT NULL,
  `coords`      LONGTEXT     DEFAULT NULL,
  `job`         VARCHAR(60)  NOT NULL DEFAULT 'unemployed',
  `job_grade`   INT(11)      NOT NULL DEFAULT 0,
  `job_duty`    TINYINT(1)   NOT NULL DEFAULT 0,
  `job2`        VARCHAR(60)  NOT NULL DEFAULT '',
  `job2_grade`  INT(11)      NOT NULL DEFAULT 0,
  `faction`     VARCHAR(60)  NOT NULL DEFAULT '',
  `group`       VARCHAR(60)  NOT NULL DEFAULT 'user',
  `accounts`    LONGTEXT     DEFAULT NULL,
  `inventory`   LONGTEXT     DEFAULT NULL,
  `loadout`     LONGTEXT     DEFAULT NULL,
  `licenses`    LONGTEXT     DEFAULT NULL,
  `metadata`    LONGTEXT     DEFAULT NULL,
  `address`     VARCHAR(150) DEFAULT NULL,
  `max_weight`  INT(11)      NOT NULL DEFAULT 5000,
  `is_dead`     TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `deleted_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_characters_identifier` (`identifier`),
  KEY `idx_characters_account` (`account_id`),
  KEY `idx_characters_job` (`job`),
  KEY `idx_characters_faction` (`faction`),
  KEY `idx_characters_names` (`lastname`,`firstname`),
  KEY `idx_characters_deleted` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `character_phones` (
  `identifier` VARCHAR(64) NOT NULL,
  `phone`      VARCHAR(20) NOT NULL,
  PRIMARY KEY (`identifier`),
  KEY `idx_character_phones_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `character_tattoos` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `collection` VARCHAR(100) NOT NULL,
  `hash`       VARCHAR(100) NOT NULL,
  `zone`       VARCHAR(50)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_character_tattoos_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `character_outfits` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `char_id`     INT(11)      NOT NULL,
  `name`        VARCHAR(100) NOT NULL,
  `outfit_data` LONGTEXT     DEFAULT NULL,
  `raw_skin`    LONGTEXT     DEFAULT NULL,
  `total_price` INT(11)      NOT NULL DEFAULT 0,
  `quantity`    INT(11)      NOT NULL DEFAULT 1,
  `type`        VARCHAR(30)  NOT NULL DEFAULT 'private',
  `bag_uuid`    VARCHAR(64)  DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_character_outfits_char` (`char_id`,`type`),
  KEY `idx_character_outfits_bag` (`bag_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ped_scales` (
  `char_id` INT(11)     NOT NULL,
  `scale`   FLOAT       NOT NULL DEFAULT 1,
  PRIMARY KEY (`char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `owned_peds` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `ped_model`  VARCHAR(60)  NOT NULL,
  `name`       VARCHAR(100) DEFAULT NULL,
  `image`      VARCHAR(255) DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_owned_peds` (`identifier`,`ped_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_licenses` (
  `id`            INT(11)     NOT NULL AUTO_INCREMENT,
  `charid`        VARCHAR(64) NOT NULL,
  `type`          VARCHAR(50) NOT NULL,
  `obtained_date` DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_licenses` (`charid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `variables` (
  `name` VARCHAR(100) NOT NULL,
  `data` LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gestion_images_settings` (
  `scope`    VARCHAR(32)  NOT NULL,
  `item_key` VARCHAR(128) NOT NULL,
  `url`      VARCHAR(1024) NOT NULL DEFAULT '',
  PRIMARY KEY (`scope`, `item_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vfw_config` (
  `key`   VARCHAR(100) NOT NULL,
  `value` LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  2. ITEMS, METIERS & SOCIETES
-- =====================================================================

CREATE TABLE IF NOT EXISTS `items` (
  `name`        VARCHAR(64)  NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `type`        VARCHAR(32)  NOT NULL DEFAULT 'item',
  `weight`      INT(11)      NOT NULL DEFAULT 0,
  `premium`     TINYINT(1)   NOT NULL DEFAULT 0,
  `perm`        VARCHAR(64)  DEFAULT NULL,
  `image`       VARCHAR(255) DEFAULT NULL,
  `description` TEXT         DEFAULT NULL,
  `data`        LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`name`),
  KEY `idx_items_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jobs` (
  `name`        VARCHAR(60)  NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `type`        VARCHAR(32)  NOT NULL DEFAULT 'job',
  `whitelisted` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_grades` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `grade`       INT(11)      NOT NULL DEFAULT 0,
  `name`        VARCHAR(60)  NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `salary`      INT(11)      NOT NULL DEFAULT 0,
  `is_boss`     TINYINT(1)   NOT NULL DEFAULT 0,
  `permissions` LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_job_grades` (`job_name`,`grade`),
  KEY `idx_job_grades_name` (`job_name`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `societies` (
  `name`       VARCHAR(60)  NOT NULL,
  `label`      VARCHAR(100) NOT NULL,
  `type`       VARCHAR(32)  NOT NULL DEFAULT 'society',
  `image`      VARCHAR(512) DEFAULT NULL,
  `banner`     VARCHAR(512) DEFAULT NULL,
  `address`    VARCHAR(150) DEFAULT NULL,
  `blip`       LONGTEXT     DEFAULT NULL,
  `management` LONGTEXT     DEFAULT NULL,
  `storage`    LONGTEXT     DEFAULT NULL,
  `custom`     LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_accounts` (
  `job_name` VARCHAR(60) NOT NULL,
  `money`    BIGINT(20)  NOT NULL DEFAULT 0,
  `bank`     BIGINT(20)  NOT NULL DEFAULT 0,
  `society`  VARCHAR(60) DEFAULT NULL,
  PRIMARY KEY (`job_name`),
  KEY `idx_society_accounts_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_grade_perms` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `job_name`   VARCHAR(60) NOT NULL,
  `grade_name` VARCHAR(60) NOT NULL,
  `perm_name`  VARCHAR(60) NOT NULL,
  `enabled`    TINYINT(1)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_society_grade_perms` (`job_name`,`grade_name`,`perm_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_favorites` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `job_name`   VARCHAR(60) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_society_favorites` (`job_name`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_services` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `identifier`  VARCHAR(64)  NOT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `started_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_society_services` (`job_name`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_custom` (
  `job_name`                  VARCHAR(60)  NOT NULL,
  `image`                     VARCHAR(255) DEFAULT NULL,
  `allow_custom_announcement` TINYINT(1)   NOT NULL DEFAULT 0,
  `weazel_perms`              LONGTEXT     DEFAULT NULL,
  `lifeinvader_perms`         LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_addon_fields` (
  `society` VARCHAR(60) NOT NULL,
  `field`   VARCHAR(60) NOT NULL,
  `value`   LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`society`,`field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_chest_access` (
  `job_name` VARCHAR(60) NOT NULL,
  `subject`  VARCHAR(80) NOT NULL,
  `allowed`  TINYINT(1)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`job_name`,`subject`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_billings` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`          VARCHAR(60)  NOT NULL,
  `sender`            VARCHAR(100) DEFAULT NULL,
  `receiver`          VARCHAR(100) DEFAULT NULL,
  `target_identifier` VARCHAR(64)  DEFAULT NULL,
  `date`              DATETIME     DEFAULT NULL,
  `total`             BIGINT(20)   NOT NULL DEFAULT 0,
  `base_cost`         BIGINT(20)   NOT NULL DEFAULT 0,
  `statut`            TINYINT(4)   NOT NULL DEFAULT 0,
  `type`              VARCHAR(32)  NOT NULL DEFAULT 'facture',
  `items`             LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_society_billings_job` (`job_name`,`statut`),
  KEY `idx_society_billings_target` (`target_identifier`,`statut`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_doorbells` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`       VARCHAR(60)  NOT NULL,
  `x`              DOUBLE       NOT NULL DEFAULT 0,
  `y`              DOUBLE       NOT NULL DEFAULT 0,
  `z`              DOUBLE       NOT NULL DEFAULT 0,
  `message`        VARCHAR(255) DEFAULT NULL,
  `caller_message` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_society_doorbells_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_craft_recipes` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `item`        VARCHAR(64)  NOT NULL,
  `label`       VARCHAR(100) DEFAULT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 1,
  `ingredients` LONGTEXT     DEFAULT NULL,
  `craft_time`  INT(11)      NOT NULL DEFAULT 5000,
  PRIMARY KEY (`id`),
  KEY `idx_society_craft_recipes_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_craft_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `identifier`  VARCHAR(64)  NOT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `item`        VARCHAR(64)  NOT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 1,
  `result`      VARCHAR(32)  DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_society_craft_logs_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_customs_invoices` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `job`            VARCHAR(60)  NOT NULL,
  `sender_id`      VARCHAR(64)  DEFAULT NULL,
  `target_id`      VARCHAR(64)  DEFAULT NULL,
  `plate`          VARCHAR(12)  DEFAULT NULL,
  `vehicle_name`   VARCHAR(100) DEFAULT NULL,
  `total`          BIGINT(20)   NOT NULL DEFAULT 0,
  `status`         VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `vehicle_props`  LONGTEXT     DEFAULT NULL,
  `original_props` LONGTEXT     DEFAULT NULL,
  `created_at`     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_society_customs_invoices_job` (`job`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `employment_contracts` (
  `id`                   INT(11)     NOT NULL AUTO_INCREMENT,
  `contract_id`          VARCHAR(64) NOT NULL,
  `job_name`             VARCHAR(60) NOT NULL,
  `role`                 VARCHAR(60) DEFAULT NULL,
  `recruiter_identifier` VARCHAR(64) NOT NULL,
  `target_identifier`    VARCHAR(64) NOT NULL,
  `status`               VARCHAR(20) NOT NULL DEFAULT 'pending',
  `created_at`           DATETIME    DEFAULT NULL,
  `metadata`             LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_employment_contracts` (`contract_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mecano_commandes` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `job`        VARCHAR(60)  NOT NULL,
  `plate`      VARCHAR(12)  NOT NULL,
  `name`       VARCHAR(100) DEFAULT NULL,
  `props`      LONGTEXT     DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_mecano_commandes_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `custom_prices_base` (
  `mod_type`        VARCHAR(60) NOT NULL,
  `base_price`      INT(11)     NOT NULL DEFAULT 0,
  `price_per_level` INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`mod_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `custom_prices_category` (
  `category`  VARCHAR(60) NOT NULL,
  `modifier`  FLOAT       NOT NULL DEFAULT 1,
  `overrides` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `custom_prices_model` (
  `model`     VARCHAR(60) NOT NULL,
  `modifier`  FLOAT       NOT NULL DEFAULT 1,
  `overrides` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_configs` (
  `society_name`      VARCHAR(60) NOT NULL,
  `is_bar`            TINYINT(1)  NOT NULL DEFAULT 0,
  `ped_coords`        LONGTEXT    DEFAULT NULL,
  `harvest`           LONGTEXT    DEFAULT NULL,
  `processing_points` LONGTEXT    DEFAULT NULL,
  `harvest_anim`      LONGTEXT    DEFAULT NULL,
  `processing_anim`   LONGTEXT    DEFAULT NULL,
  `selling_anim`      LONGTEXT    DEFAULT NULL,
  `items`             LONGTEXT    DEFAULT NULL,
  `society_percent`   INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`society_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `farm_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `society`     VARCHAR(60)  NOT NULL,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `action`      VARCHAR(40)  DEFAULT NULL,
  `item`        VARCHAR(64)  DEFAULT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 0,
  `amount`      BIGINT(20)   NOT NULL DEFAULT 0,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_farm_logs_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bar_menu_items` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `item`        VARCHAR(64)  NOT NULL,
  `section`     VARCHAR(60)  DEFAULT NULL,
  `label`       VARCHAR(100) DEFAULT NULL,
  `description` TEXT         DEFAULT NULL,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `position`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bar_menu_items` (`job_name`,`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bar_carte_points` (
  `id`       INT(11)     NOT NULL AUTO_INCREMENT,
  `job_name` VARCHAR(60) NOT NULL,
  `x`        DOUBLE      NOT NULL DEFAULT 0,
  `y`        DOUBLE      NOT NULL DEFAULT 0,
  `z`        DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_bar_carte_points_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `restaurant_stations` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `resto_key`    VARCHAR(60) NOT NULL,
  `loc_key`      VARCHAR(60) NOT NULL,
  `station_key`  VARCHAR(60) NOT NULL,
  `data`         LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_restaurant_stations` (`resto_key`,`loc_key`,`station_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `restaurant_delivery_logs` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `brand`        VARCHAR(60)  NOT NULL,
  `job_name`     VARCHAR(60)  NOT NULL,
  `identifier`   VARCHAR(64)  DEFAULT NULL,
  `player_name`  VARCHAR(100) DEFAULT NULL,
  `reward`       BIGINT(20)   NOT NULL DEFAULT 0,
  `society_gain` BIGINT(20)   NOT NULL DEFAULT 0,
  `tip`          BIGINT(20)   NOT NULL DEFAULT 0,
  `created_at`   DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_restaurant_delivery_logs` (`brand`,`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_traffic_zones` (
  `id`   INT(11)     NOT NULL AUTO_INCREMENT,
  `job`  VARCHAR(60) NOT NULL,
  `data` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_job_traffic_zones_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_armories` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `jobs`         LONGTEXT     DEFAULT NULL,
  `pos`          LONGTEXT     DEFAULT NULL,
  `npc_pos`      LONGTEXT     DEFAULT NULL,
  `npc_model`    VARCHAR(60)  DEFAULT NULL,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`  INT(11)      NOT NULL DEFAULT 1,
  `blip_color`   INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`   FLOAT        NOT NULL DEFAULT 0.5,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_armory_weapons` (
  `id`             INT(11)     NOT NULL AUTO_INCREMENT,
  `armory_id`      INT(11)     NOT NULL,
  `item_name`      VARCHAR(64) NOT NULL,
  `min_grade`      INT(11)     NOT NULL DEFAULT 0,
  `max_stock`      INT(11)     NOT NULL DEFAULT 0,
  `max_per_player` INT(11)     NOT NULL DEFAULT 1,
  `current_out`    INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_job_armory_weapons_armory` (`armory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_armory_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `armory_id`   INT(11)      NOT NULL,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `item_name`   VARCHAR(64)  DEFAULT NULL,
  `action`      VARCHAR(32)  DEFAULT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 1,
  `created_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_job_armory_logs_armory` (`armory_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_equipments` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `jobs`         LONGTEXT     DEFAULT NULL,
  `pos`          LONGTEXT     DEFAULT NULL,
  `npc_pos`      LONGTEXT     DEFAULT NULL,
  `npc_model`    VARCHAR(60)  DEFAULT NULL,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`  INT(11)      NOT NULL DEFAULT 1,
  `blip_color`   INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`   FLOAT        NOT NULL DEFAULT 0.5,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_equipment_items` (
  `id`             INT(11)     NOT NULL AUTO_INCREMENT,
  `equipment_id`   INT(11)     NOT NULL,
  `item_name`      VARCHAR(64) NOT NULL,
  `min_grade`      INT(11)     NOT NULL DEFAULT 0,
  `max_stock`      INT(11)     NOT NULL DEFAULT 0,
  `max_per_player` INT(11)     NOT NULL DEFAULT 1,
  `current_out`    INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_job_equipment_items_eq` (`equipment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `job_equipment_logs` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `equipment_id` INT(11)      NOT NULL,
  `identifier`   VARCHAR(64)  DEFAULT NULL,
  `player_name`  VARCHAR(100) DEFAULT NULL,
  `item_name`    VARCHAR(64)  DEFAULT NULL,
  `action`       VARCHAR(32)  DEFAULT NULL,
  `quantity`     INT(11)      NOT NULL DEFAULT 1,
  `created_at`   DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_job_equipment_logs_eq` (`equipment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  3. VEHICULES, GARAGES, FOURRIERES, CONCESSIONS & LOCATION
-- =====================================================================

CREATE TABLE IF NOT EXISTS `owned_vehicles` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `plate`        VARCHAR(12)  NOT NULL,
  `owner`        VARCHAR(64)  NOT NULL DEFAULT '',
  `owner_charid` INT(11)      DEFAULT NULL,
  `vehName`      VARCHAR(60)  NOT NULL,
  `model`        VARCHAR(60)  DEFAULT NULL,
  `label`        VARCHAR(100) DEFAULT NULL,
  `props`        LONGTEXT     DEFAULT NULL,
  `stored`       TINYINT(1)   NOT NULL DEFAULT 1,
  `pounded`      TINYINT(1)   NOT NULL DEFAULT 0,
  `pound_id`     INT(11)      DEFAULT NULL,
  `garage_id`    INT(11)      DEFAULT NULL,
  `engineHealth` FLOAT        NOT NULL DEFAULT 1000,
  `bodyHealth`   FLOAT        NOT NULL DEFAULT 1000,
  `fuelLevel`    FLOAT        NOT NULL DEFAULT 100,
  `modTurbo`     TINYINT(1)   NOT NULL DEFAULT 0,
  `group_type`   VARCHAR(32)  DEFAULT NULL,
  `group_name`   VARCHAR(60)  DEFAULT NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_owned_vehicles_plate` (`plate`),
  KEY `idx_owned_vehicles_owner` (`owner`),
  KEY `idx_owned_vehicles_group` (`group_type`,`group_name`),
  KEY `idx_owned_vehicles_garage` (`garage_id`),
  KEY `idx_owned_vehicles_pound` (`pound_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_label_overrides` (
  `model` VARCHAR(60)  NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_storage_config` (
  `model`        VARCHAR(60) NOT NULL,
  `trunk_weight` INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garages` (
  `id`              INT(11)      NOT NULL AUTO_INCREMENT,
  `name`            VARCHAR(100) NOT NULL,
  `type`            VARCHAR(32)  NOT NULL DEFAULT 'public',
  `vehType`         VARCHAR(32)  NOT NULL DEFAULT 'car',
  `position`        LONGTEXT     DEFAULT NULL,
  `spawnPosition`   LONGTEXT     DEFAULT NULL,
  `deletePosition`  LONGTEXT     DEFAULT NULL,
  `secondaryGarage` LONGTEXT     DEFAULT NULL,
  `access`          LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pounds` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `label`          VARCHAR(100) NOT NULL,
  `position`       LONGTEXT     DEFAULT NULL,
  `spawnPositions` LONGTEXT     DEFAULT NULL,
  `useMarker`      TINYINT(1)   NOT NULL DEFAULT 1,
  `pedModel`       VARCHAR(60)  DEFAULT NULL,
  `price`          INT(11)      NOT NULL DEFAULT 0,
  `zone`           LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_garages` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `name`              VARCHAR(100) NOT NULL,
  `job`               VARCHAR(60)  NOT NULL,
  `position`          LONGTEXT     DEFAULT NULL,
  `spawn_positions`   LONGTEXT     DEFAULT NULL,
  `despawn_position`  LONGTEXT     DEFAULT NULL,
  `vehicles`          LONGTEXT     DEFAULT NULL,
  `ped_model`         VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_garages_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `job`          VARCHAR(60)  NOT NULL,
  `concess_type` VARCHAR(32)  NOT NULL DEFAULT 'car',
  `automatic`    TINYINT(1)   NOT NULL DEFAULT 0,
  `ped_model`    VARCHAR(60)  DEFAULT NULL,
  `catalog`      LONGTEXT     DEFAULT NULL,
  `preview`      LONGTEXT     DEFAULT NULL,
  `spawn`        LONGTEXT     DEFAULT NULL,
  `showcase`     LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess_categories` (
  `name`         VARCHAR(60) NOT NULL,
  `concess_type` VARCHAR(32) NOT NULL DEFAULT 'car',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess_vehicles` (
  `model`    VARCHAR(60)  NOT NULL,
  `name`     VARCHAR(100) NOT NULL,
  `price`    BIGINT(20)   NOT NULL DEFAULT 0,
  `category` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`model`),
  KEY `idx_concess_vehicles_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess_stock` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `concess_id` INT(11)      NOT NULL,
  `model`      VARCHAR(60)  NOT NULL,
  `name`       VARCHAR(100) DEFAULT NULL,
  `quantity`   INT(11)      NOT NULL DEFAULT 0,
  `in_test`    TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_concess_stock` (`concess_id`,`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess_logs` (
  `id`          INT(11)     NOT NULL AUTO_INCREMENT,
  `concess_id`  INT(11)     NOT NULL,
  `type`        VARCHAR(32) DEFAULT NULL,
  `description` TEXT        DEFAULT NULL,
  `player`      VARCHAR(100) DEFAULT NULL,
  `amount`      BIGINT(20)  NOT NULL DEFAULT 0,
  `date`        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_concess_logs_concess` (`concess_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `concess_key_duplicates` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `plate`      VARCHAR(12) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_concess_key_duplicates` (`plate`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_rental_points` (
  `iId`          INT(11)      NOT NULL AUTO_INCREMENT,
  `iType`        INT(11)      NOT NULL DEFAULT 0,
  `sName`        VARCHAR(100) NOT NULL,
  `tPos`         LONGTEXT     DEFAULT NULL,
  `sPedModel`    VARCHAR(60)  DEFAULT NULL,
  `tVehiclePos`  LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`iId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_rental_catalog` (
  `id`    INT(11)      NOT NULL AUTO_INCREMENT,
  `iType` INT(11)      NOT NULL DEFAULT 0,
  `name`  VARCHAR(60)  NOT NULL,
  `label` VARCHAR(100) DEFAULT NULL,
  `price` INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_vehicle_rental_catalog_type` (`iType`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_rental_active` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `owner`        VARCHAR(64)  NOT NULL,
  `iType`        INT(11)      NOT NULL DEFAULT 0,
  `iPointId`     INT(11)      DEFAULT NULL,
  `sVehicleName` VARCHAR(60)  DEFAULT NULL,
  `sLabel`       VARCHAR(100) DEFAULT NULL,
  `sPlate`       VARCHAR(12)  NOT NULL,
  `iPrice`       INT(11)      NOT NULL DEFAULT 0,
  `rented_at`    DATETIME     DEFAULT NULL,
  `expires_at`   DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_vehicle_rental_active_plate` (`sPlate`),
  KEY `idx_vehicle_rental_active_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chameleon_colors` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `label`        VARCHAR(100) NOT NULL,
  `native_color` INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vehicle_chameleon` (
  `plate`        VARCHAR(12) NOT NULL,
  `native_color` INT(11)     NOT NULL DEFAULT 0,
  `applied_by`   VARCHAR(64) DEFAULT NULL,
  `applied_at`   DATETIME    DEFAULT NULL,
  PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garage_illegal_points` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(100) NOT NULL,
  `coords_x`   DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`   DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`   DOUBLE       NOT NULL DEFAULT 0,
  `coords_h`   DOUBLE       NOT NULL DEFAULT 0,
  `is_paid`    TINYINT(1)   NOT NULL DEFAULT 0,
  `price`      INT(11)      NOT NULL DEFAULT 0,
  `plate_mode` VARCHAR(32)  NOT NULL DEFAULT 'random',
  `allowed_jobs` LONGTEXT DEFAULT NULL,
  `allowed_factions` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `garage_illegal_log` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `point_id`   INT(11)     NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `old_plate`  VARCHAR(12) DEFAULT NULL,
  `new_plate`  VARCHAR(12) DEFAULT NULL,
  `charged`    INT(11)     NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_garage_illegal_log_point` (`point_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  4. INVENTAIRE, COFFRES, CASIERS, SACS & MAGASINS
-- =====================================================================

CREATE TABLE IF NOT EXISTS `chests` (
  `chest_id`   VARCHAR(100) NOT NULL,
  `name`       VARCHAR(100) DEFAULT NULL,
  `label`      VARCHAR(100) DEFAULT NULL,
  `owner`      VARCHAR(64)  DEFAULT NULL,
  `max_weight` INT(11)      NOT NULL DEFAULT 100000,
  `max_slots`  INT(11)      NOT NULL DEFAULT 40,
  `items`      LONGTEXT     DEFAULT NULL,
  `updated_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`chest_id`),
  KEY `idx_chests_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chest_items` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `chest_id` VARCHAR(100) NOT NULL,
  `slot`     INT(11)      NOT NULL DEFAULT 0,
  `name`     VARCHAR(64)  NOT NULL,
  `count`    INT(11)      NOT NULL DEFAULT 0,
  `meta`     LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_chest_items_chest` (`chest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chest_history` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `chest_id`    VARCHAR(100) NOT NULL,
  `citizenid`   VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `action`      VARCHAR(32)  DEFAULT NULL,
  `item_name`   VARCHAR(64)  DEFAULT NULL,
  `count`       INT(11)      NOT NULL DEFAULT 0,
  `meta`        LONGTEXT     DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_chest_history_chest` (`chest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chest_builder` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `coords`         LONGTEXT     DEFAULT NULL,
  `label`          VARCHAR(100) DEFAULT NULL,
  `access_name`    VARCHAR(60)  DEFAULT NULL,
  `access_label`   VARCHAR(100) DEFAULT NULL,
  `grade_min_put`  INT(11)      NOT NULL DEFAULT 0,
  `grade_min_take` INT(11)      NOT NULL DEFAULT 0,
  `pincode`        VARCHAR(12)  DEFAULT NULL,
  `max_weight`     INT(11)      NOT NULL DEFAULT 100000,
  `max_slots`      INT(11)      NOT NULL DEFAULT 40,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `deposit_points` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `coords`        LONGTEXT     DEFAULT NULL,
  `label`         VARCHAR(100) DEFAULT NULL,
  `access_name`   VARCHAR(60)  DEFAULT NULL,
  `manager_grade` INT(11)      NOT NULL DEFAULT 0,
  `max_weight`    INT(11)      NOT NULL DEFAULT 100000,
  `max_slots`     INT(11)      NOT NULL DEFAULT 40,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `deposit_entries` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `point_id`  INT(11)      NOT NULL,
  `citizenid` VARCHAR(64)  NOT NULL,
  `name`      VARCHAR(100) DEFAULT NULL,
  `chest_id`  VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_deposit_entries` (`point_id`,`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `lockers` (
  `id`              INT(11)      NOT NULL AUTO_INCREMENT,
  `label`           VARCHAR(100) NOT NULL,
  `position`        LONGTEXT     DEFAULT NULL,
  `whitelist_type`  VARCHAR(32)  DEFAULT NULL,
  `whitelist_value` VARCHAR(100) DEFAULT NULL,
  `show_blip`       TINYINT(1)   NOT NULL DEFAULT 0,
  `floating_z`      FLOAT        NOT NULL DEFAULT 0,
  `outfits`         LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_lockers` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `label`      VARCHAR(100) NOT NULL,
  `position`   LONGTEXT     DEFAULT NULL,
  `job`        VARCHAR(60)  NOT NULL,
  `job_name`   VARCHAR(60)  DEFAULT NULL,
  `max_weight` INT(11)      NOT NULL DEFAULT 100000,
  `max_slots`  INT(11)      NOT NULL DEFAULT 40,
  `floating_z` FLOAT        NOT NULL DEFAULT 0,
  `grade_min`  INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_society_lockers_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_locker_chests` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `locker_id`   INT(11)      NOT NULL,
  `identifier`  VARCHAR(64)  NOT NULL,
  `chest_id`    VARCHAR(100) NOT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `job`         VARCHAR(60)  DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_society_locker_chests` (`locker_id`,`identifier`),
  KEY `idx_society_locker_chests_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table historique (fallback lu par core si society_locker_chests est vide)
CREATE TABLE IF NOT EXISTS `society_locker_employees` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `locker_id`   INT(11)      NOT NULL,
  `identifier`  VARCHAR(64)  NOT NULL,
  `chest_id`    VARCHAR(100) DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `job`         VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_society_locker_employees` (`locker_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `society_lockers_archived` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `locker_id`    INT(11)      NOT NULL,
  `job`          VARCHAR(60)  NOT NULL,
  `identifier`   VARCHAR(64)  NOT NULL,
  `player_name`  VARCHAR(100) DEFAULT NULL,
  `chest_id`     VARCHAR(100) DEFAULT NULL,
  `items`        LONGTEXT     DEFAULT NULL,
  `item_count`   INT(11)      NOT NULL DEFAULT 0,
  `total_weight` INT(11)      NOT NULL DEFAULT 0,
  `archived_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_society_lockers_archived_job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table historique (fallback lu par core si society_lockers_archived est vide)
CREATE TABLE IF NOT EXISTS `society_locker_archives` (
  `archived_id` INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `locker_id`   INT(11)      DEFAULT NULL,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `chest_id`    VARCHAR(100) DEFAULT NULL,
  `items`       LONGTEXT     DEFAULT NULL,
  `archived_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`archived_id`),
  KEY `idx_society_locker_archives_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bag_categories` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `label`       VARCHAR(100) NOT NULL,
  `sex`         VARCHAR(10)  DEFAULT NULL,
  `drawable_id` INT(11)      NOT NULL DEFAULT 0,
  `capacity`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bags` (
  `bag_uuid`    VARCHAR(64) NOT NULL,
  `items`       LONGTEXT    DEFAULT NULL,
  `capacity`    INT(11)     NOT NULL DEFAULT 0,
  `drawable_id` INT(11)     NOT NULL DEFAULT 0,
  `max_slots`   INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`bag_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `placed_clothes_bags` (
  `bag_uuid`      VARCHAR(64) NOT NULL,
  `owner_char_id` INT(11)     DEFAULT NULL,
  `x`             DOUBLE      NOT NULL DEFAULT 0,
  `y`             DOUBLE      NOT NULL DEFAULT 0,
  `z`             DOUBLE      NOT NULL DEFAULT 0,
  `rotation`      DOUBLE      NOT NULL DEFAULT 0,
  `metadata`      LONGTEXT    DEFAULT NULL,
  `net_id`        INT(11)     DEFAULT NULL,
  PRIMARY KEY (`bag_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `clothes_prices` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `sex`      VARCHAR(10)  NOT NULL,
  `category` VARCHAR(60)  NOT NULL,
  `label`    VARCHAR(100) DEFAULT NULL,
  `price`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_clothes_prices` (`sex`,`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `clothes_blacklist` (
  `id`          INT(11)     NOT NULL AUTO_INCREMENT,
  `gender`      VARCHAR(10) NOT NULL,
  `db_key`      VARCHAR(60) NOT NULL,
  `drawable_id` INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_clothes_blacklist` (`gender`,`db_key`,`drawable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `shops` (
  `id`               INT(11)     NOT NULL AUTO_INCREMENT,
  `type`             VARCHAR(60) NOT NULL,
  `position`         LONGTEXT    DEFAULT NULL,
  `blip`             INT(11)     NOT NULL DEFAULT 0,
  `blip_color`       INT(11)     NOT NULL DEFAULT 0,
  `price_multiplier` FLOAT       NOT NULL DEFAULT 1,
  `chairs`           LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_shops_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ltd_items` (
  `item`         VARCHAR(64)  NOT NULL,
  `label`        VARCHAR(100) DEFAULT NULL,
  `normal_price` INT(11)      NOT NULL DEFAULT 0,
  `buy_price`    INT(11)      NOT NULL DEFAULT 0,
  `sell_price`   INT(11)      NOT NULL DEFAULT 0,
  `position`     INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ltd_society_catalog` (
  `society` VARCHAR(60) NOT NULL,
  `item`    VARCHAR(64) NOT NULL,
  `price`   INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`society`,`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ltd_catalog_points` (
  `id`      INT(11)     NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(60) NOT NULL,
  `x`       DOUBLE      NOT NULL DEFAULT 0,
  `y`       DOUBLE      NOT NULL DEFAULT 0,
  `z`       DOUBLE      NOT NULL DEFAULT 0,
  `h`       DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_ltd_catalog_points_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ltd_delivery_points` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `society`   VARCHAR(60)  NOT NULL,
  `kind`      VARCHAR(32)  NOT NULL DEFAULT 'delivery',
  `x`         DOUBLE       NOT NULL DEFAULT 0,
  `y`         DOUBLE       NOT NULL DEFAULT 0,
  `z`         DOUBLE       NOT NULL DEFAULT 0,
  `h`         DOUBLE       NOT NULL DEFAULT 0,
  `npc_name`  VARCHAR(100) DEFAULT NULL,
  `npc_model` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ltd_delivery_points_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ltd_delivery_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `society`     VARCHAR(60)  NOT NULL,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `delivered`   INT(11)      NOT NULL DEFAULT 0,
  `payment`     BIGINT(20)   NOT NULL DEFAULT 0,
  `tip`         BIGINT(20)   NOT NULL DEFAULT 0,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ltd_delivery_logs_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crafting_recipes` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `label`        VARCHAR(100) DEFAULT NULL,
  `output_item`  VARCHAR(64)  DEFAULT NULL,
  `output_count` INT(11)      NOT NULL DEFAULT 1,
  `ingredients`  LONGTEXT     DEFAULT NULL,
  `craft_time`   INT(11)      NOT NULL DEFAULT 5000,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crafting_recipes_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `legal_stations` (
  `id`              INT(11)      NOT NULL AUTO_INCREMENT,
  `name`            VARCHAR(100) NOT NULL,
  `coords_x`        DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`        DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`        DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`      DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`        DOUBLE       DEFAULT NULL,
  `marker_y`        DOUBLE       DEFAULT NULL,
  `marker_z`        DOUBLE       DEFAULT NULL,
  `prop_model`      VARCHAR(60)  DEFAULT NULL,
  `blip_enabled`    TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`     INT(11)      NOT NULL DEFAULT 1,
  `blip_color`      INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`      FLOAT        NOT NULL DEFAULT 0.5,
  `blip_label`      VARCHAR(100) DEFAULT NULL,
  `job_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `job_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `legal_station_recipes` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `station_id` INT(11)     NOT NULL,
  `recipe_id`  INT(11)     NOT NULL,
  `slot_key`   VARCHAR(60) DEFAULT NULL,
  `position`   INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_legal_station_recipes_station` (`station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `legal_activity_sellers` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `activity`     VARCHAR(60) NOT NULL,
  `seller_index` INT(11)     NOT NULL DEFAULT 0,
  `model`        VARCHAR(60) DEFAULT NULL,
  `x`            DOUBLE      NOT NULL DEFAULT 0,
  `y`            DOUBLE      NOT NULL DEFAULT 0,
  `z`            DOUBLE      NOT NULL DEFAULT 0,
  `w`            DOUBLE      NOT NULL DEFAULT 0,
  `visible`      TINYINT(1)  NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_legal_activity_sellers` (`activity`,`seller_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `legal_activity_logs` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64) NOT NULL,
  `activity`     VARCHAR(60) NOT NULL,
  `item`         VARCHAR(64) DEFAULT NULL,
  `count`        INT(11)     NOT NULL DEFAULT 0,
  `amount`       BIGINT(20)  NOT NULL DEFAULT 0,
  `payment_type` VARCHAR(32) DEFAULT NULL,
  `created_at`   TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_legal_activity_logs_activity` (`activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  5. BANQUE & FACTURATION
-- =====================================================================

CREATE TABLE IF NOT EXISTS `bank_ibans` (
  `iban`       VARCHAR(34)  NOT NULL,
  `owner_type` VARCHAR(20)  NOT NULL DEFAULT 'player',
  `owner_key`  VARCHAR(64)  NOT NULL,
  `label`      VARCHAR(100) DEFAULT NULL,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`iban`),
  KEY `idx_bank_ibans_owner` (`owner_type`,`owner_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `bank_transactions` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `iban`         VARCHAR(34)  NOT NULL,
  `account_type` TINYINT(4)   NOT NULL DEFAULT 1,
  `label`        VARCHAR(150) DEFAULT NULL,
  `status`       VARCHAR(32)  DEFAULT NULL,
  `amount`       BIGINT(20)   NOT NULL DEFAULT 0,
  `value`        BIGINT(20)   NOT NULL DEFAULT 0,
  `positive`     TINYINT(1)   NOT NULL DEFAULT 1,
  `date`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_bank_transactions_iban` (`iban`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `billing_invoices` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `billing_id`        INT(11)      DEFAULT NULL,
  `target_identifier` VARCHAR(64)  NOT NULL,
  `sender_identifier` VARCHAR(64)  DEFAULT NULL,
  `sender_name`       VARCHAR(100) DEFAULT NULL,
  `receiver_name`     VARCHAR(100) DEFAULT NULL,
  `receiver_company`  VARCHAR(100) DEFAULT NULL,
  `society`           VARCHAR(60)  DEFAULT NULL,
  `society_label`     VARCHAR(100) DEFAULT NULL,
  `society_image`     VARCHAR(255) DEFAULT NULL,
  `bill_type`         VARCHAR(32)  DEFAULT NULL,
  `items`             LONGTEXT     DEFAULT NULL,
  `reduce`            INT(11)      NOT NULL DEFAULT 0,
  `total`             BIGINT(20)   NOT NULL DEFAULT 0,
  `status`            VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `payment_method`    VARCHAR(32)  DEFAULT NULL,
  `receipt_sender`    LONGTEXT     DEFAULT NULL,
  `receipt_receiver`  LONGTEXT     DEFAULT NULL,
  `created_at`        DATETIME     DEFAULT NULL,
  `paid_at`           DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_billing_invoices_target` (`target_identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  6. PROPRIETES, MOTELS, DYNASTY & DECORATION
-- =====================================================================

CREATE TABLE IF NOT EXISTS `properties` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `name`              VARCHAR(150) NOT NULL,
  `property_name`     VARCHAR(150) DEFAULT NULL,
  `property_key`      VARCHAR(100) DEFAULT NULL,
  `type`              VARCHAR(60)  DEFAULT NULL,
  `category`          VARCHAR(60)  DEFAULT NULL,
  `owner`             VARCHAR(64)  NOT NULL DEFAULT '',
  `access`            VARCHAR(32)  NOT NULL DEFAULT 'fermer',
  `pos`               LONGTEXT     DEFAULT NULL,
  `vehicle_pos`       LONGTEXT     DEFAULT NULL,
  `max_places`        INT(11)      NOT NULL DEFAULT 0,
  `deco`              LONGTEXT     DEFAULT NULL,
  `is_perquisitioned` TINYINT(1)   NOT NULL DEFAULT 0,
  `contract_type`     VARCHAR(32)  DEFAULT NULL,
  `total_price`       BIGINT(20)   NOT NULL DEFAULT 0,
  `rent_price`        BIGINT(20)   NOT NULL DEFAULT 0,
  `rental_expire`     BIGINT(20)   NOT NULL DEFAULT 0,
  `dynasty_society`   VARCHAR(60)  DEFAULT NULL,
  `created_at`        DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_properties_owner` (`owner`),
  KEY `idx_properties_key` (`property_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `properties_deleted` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `property_id`      INT(11)      NOT NULL,
  `name`             VARCHAR(150) DEFAULT NULL,
  `type`             VARCHAR(60)  DEFAULT NULL,
  `payload`          LONGTEXT     DEFAULT NULL,
  `chest_data`       LONGTEXT     DEFAULT NULL,
  `chest_max_weight` INT(11)      NOT NULL DEFAULT 0,
  `delete_reason`    VARCHAR(60)  DEFAULT NULL,
  `deleted_by`       VARCHAR(64)  DEFAULT NULL,
  `deleted_at`       DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `property_access` (
  `id`            INT(11)     NOT NULL AUTO_INCREMENT,
  `property_id`   INT(11)     NOT NULL,
  `identifier`    VARCHAR(64) NOT NULL,
  `hide_identity` TINYINT(1)  NOT NULL DEFAULT 0,
  `granted_at`    DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_property_access` (`property_id`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `property_garage_vehicles` (
  `id`          INT(11)     NOT NULL AUTO_INCREMENT,
  `property_id` INT(11)     NOT NULL,
  `plate`       VARCHAR(12) NOT NULL,
  `model`       VARCHAR(60) DEFAULT NULL,
  `props`       LONGTEXT    DEFAULT NULL,
  `stored_at`   DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_property_garage_vehicles` (`plate`),
  KEY `idx_property_garage_vehicles_prop` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `property_logs` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `property_id`   INT(11)      NOT NULL,
  `property_name` VARCHAR(150) DEFAULT NULL,
  `action`        VARCHAR(60)  DEFAULT NULL,
  `identifier`    VARCHAR(64)  DEFAULT NULL,
  `player_name`   VARCHAR(100) DEFAULT NULL,
  `details`       LONGTEXT     DEFAULT NULL,
  `created_at`    DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_property_logs_property` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `property_deco_saves` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `name`       VARCHAR(100) NOT NULL,
  `type`       VARCHAR(60)  DEFAULT NULL,
  `deco`       LONGTEXT     DEFAULT NULL,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_property_deco_saves_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dynasty_prices` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `category`     VARCHAR(60)  NOT NULL,
  `property_key` VARCHAR(100) NOT NULL,
  `sell`         BIGINT(20)   NOT NULL DEFAULT 0,
  `rent`         BIGINT(20)   NOT NULL DEFAULT 0,
  `enabled`      TINYINT(1)   NOT NULL DEFAULT 1,
  `rent_enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dynasty_prices` (`category`,`property_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dynasty_contracts` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `agent_identifier`  VARCHAR(64)  NOT NULL,
  `agent_name`        VARCHAR(100) DEFAULT NULL,
  `agent_society`     VARCHAR(60)  DEFAULT NULL,
  `buyer_identifier`  VARCHAR(64)  NOT NULL,
  `buyer_name`        VARCHAR(100) DEFAULT NULL,
  `property_id`       INT(11)      DEFAULT NULL,
  `property_name`     VARCHAR(150) DEFAULT NULL,
  `property_key`      VARCHAR(100) DEFAULT NULL,
  `custom_name`       VARCHAR(150) DEFAULT NULL,
  `category`          VARCHAR(60)  DEFAULT NULL,
  `category_label`    VARCHAR(100) DEFAULT NULL,
  `capacity`          INT(11)      NOT NULL DEFAULT 0,
  `contract_type`     VARCHAR(32)  DEFAULT NULL,
  `owner_type`        VARCHAR(32)  DEFAULT NULL,
  `owner_value`       VARCHAR(100) DEFAULT NULL,
  `group_label`       VARCHAR(100) DEFAULT NULL,
  `unit_price`        BIGINT(20)   NOT NULL DEFAULT 0,
  `duration`          INT(11)      NOT NULL DEFAULT 0,
  `price`             BIGINT(20)   NOT NULL DEFAULT 0,
  `pos`               LONGTEXT     DEFAULT NULL,
  `vehicle_pos`       LONGTEXT     DEFAULT NULL,
  `status`            VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `created_at`        DATETIME     DEFAULT NULL,
  `signed_date`       DATETIME     DEFAULT NULL,
  `expiry_date`       DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_dynasty_contracts_status` (`status`),
  KEY `idx_dynasty_contracts_buyer` (`buyer_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `motels` (
  `id`                   INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                 VARCHAR(100) NOT NULL,
  `price_per_hour`       INT(11)      NOT NULL DEFAULT 0,
  `duplicate_key_price`  INT(11)      NOT NULL DEFAULT 0,
  `npc_model`            VARCHAR(60)  DEFAULT NULL,
  `npc_coords`           LONGTEXT     DEFAULT NULL,
  `blip_enabled`         TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_sprite`          INT(11)      NOT NULL DEFAULT 1,
  `blip_color`           INT(11)      NOT NULL DEFAULT 1,
  `chest_max_weight`     INT(11)      NOT NULL DEFAULT 100000,
  `chest_max_slots`      INT(11)      NOT NULL DEFAULT 40,
  `promotions`           LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `motel_rooms` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `motel_id`         INT(11)      NOT NULL,
  `room_number`      INT(11)      NOT NULL DEFAULT 0,
  `label`            VARCHAR(100) DEFAULT NULL,
  `price_override`   INT(11)      DEFAULT NULL,
  `doorlock_ids`     LONGTEXT     DEFAULT NULL,
  `icon_offsets`     LONGTEXT     DEFAULT NULL,
  `chest_coords`     LONGTEXT     DEFAULT NULL,
  `chest_max_weight` INT(11)      DEFAULT NULL,
  `chest_max_slots`  INT(11)      DEFAULT NULL,
  `promotions`       LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_motel_rooms_motel` (`motel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `motel_rentals` (
  `id`                    INT(11)      NOT NULL AUTO_INCREMENT,
  `room_id`               INT(11)      NOT NULL,
  `motel_id`              INT(11)      NOT NULL,
  `identifier`            VARCHAR(64)  NOT NULL,
  `player_name`           VARCHAR(100) DEFAULT NULL,
  `pincode`               VARCHAR(12)  DEFAULT NULL,
  `start_at`              BIGINT(20)   NOT NULL DEFAULT 0,
  `expire_at`             BIGINT(20)   NOT NULL DEFAULT 0,
  `total_duration_hours`  INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_motel_rentals_room` (`room_id`),
  KEY `idx_motel_rentals_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `motel_storage` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  NOT NULL,
  `motel_id`    INT(11)      NOT NULL,
  `motel_name`  VARCHAR(100) DEFAULT NULL,
  `room_number` INT(11)      NOT NULL DEFAULT 0,
  `items`       LONGTEXT     DEFAULT NULL,
  `item_count`  INT(11)      NOT NULL DEFAULT 0,
  `expires_at`  BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_motel_storage_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `motel_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `motel_id`    INT(11)      NOT NULL,
  `room_id`     INT(11)      DEFAULT NULL,
  `room_label`  VARCHAR(100) DEFAULT NULL,
  `action`      VARCHAR(60)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `details`     LONGTEXT     DEFAULT NULL,
  `created_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_motel_logs_motel` (`motel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `propsbuilder_props` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `model`            VARCHAR(60)  NOT NULL,
  `label`            VARCHAR(100) DEFAULT NULL,
  `position`         LONGTEXT     DEFAULT NULL,
  `owner_identifier` VARCHAR(64)  DEFAULT NULL,
  `owner_name`       VARCHAR(100) DEFAULT NULL,
  `duration_type`    TINYINT(4)   NOT NULL DEFAULT 0,
  `duration`         INT(11)      NOT NULL DEFAULT 0,
  `created_at`       BIGINT(20)   NOT NULL DEFAULT 0,
  `expires_at`       BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_propsbuilder_props_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `doorlocks` (
  `id`                    INT(11)      NOT NULL AUTO_INCREMENT,
  `label`                 VARCHAR(100) NOT NULL,
  `max_interact_distance` FLOAT        NOT NULL DEFAULT 2,
  `coords`                LONGTEXT     DEFAULT NULL,
  `doors_data`            LONGTEXT     DEFAULT NULL,
  `access`                LONGTEXT     DEFAULT NULL,
  `pincode`               VARCHAR(12)  DEFAULT NULL,
  `state`                 TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table native de la resource ox_doorlock
CREATE TABLE IF NOT EXISTS `ox_doorlock` (
  `id`   INT(11)      NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL,
  `data` LONGTEXT     NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ox_doorlock_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blips` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `label`      VARCHAR(100) NOT NULL,
  `sprite`     INT(11)      NOT NULL DEFAULT 1,
  `color`      INT(11)      NOT NULL DEFAULT 1,
  `scale`      FLOAT        NOT NULL DEFAULT 0.8,
  `x`          DOUBLE       NOT NULL DEFAULT 0,
  `y`          DOUBLE       NOT NULL DEFAULT 0,
  `z`          DOUBLE       NOT NULL DEFAULT 0,
  `created_by` VARCHAR(64)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `voice_zones` (
  `id`            INT(11)     NOT NULL AUTO_INCREMENT,
  `kind`          VARCHAR(32) NOT NULL DEFAULT 'zone',
  `x`             DOUBLE      NOT NULL DEFAULT 0,
  `y`             DOUBLE      NOT NULL DEFAULT 0,
  `z`             DOUBLE      NOT NULL DEFAULT 0,
  `radius`        FLOAT       NOT NULL DEFAULT 10,
  `amplification` FLOAT       NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `radio911_jobs` (
  `job` VARCHAR(64) NOT NULL,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_alert_zones` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(64)  NOT NULL,
  `polygon`       LONGTEXT     NOT NULL,
  `assigned_jobs` LONGTEXT     NOT NULL,
  `created_at`    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `music_playlists` (
  `id`    INT(11)      NOT NULL AUTO_INCREMENT,
  `owner` VARCHAR(64)  NOT NULL,
  `name`  VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_music_playlists_owner` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `music_playlist_tracks` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `playlist_id` INT(11)      NOT NULL,
  `title`       VARCHAR(150) NOT NULL,
  `url`         VARCHAR(500) NOT NULL,
  `position`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_music_playlist_tracks_pl` (`playlist_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  7. DISPATCH & FORCES DE L'ORDRE
-- =====================================================================

CREATE TABLE IF NOT EXISTS `dispatch_units` (
  `identifier`  VARCHAR(64) NOT NULL,
  `unit_number` VARCHAR(20) DEFAULT NULL,
  `job`         VARCHAR(60) DEFAULT NULL,
  `in_service`  TINYINT(1)  NOT NULL DEFAULT 0,
  `icon_type`   VARCHAR(32) DEFAULT NULL,
  `group_code`  VARCHAR(32) DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_calls` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `type`             VARCHAR(60)  DEFAULT NULL,
  `category`         VARCHAR(60)  DEFAULT NULL,
  `level`            INT(11)      NOT NULL DEFAULT 0,
  `job_name`         VARCHAR(60)  DEFAULT NULL,
  `unit_number`      VARCHAR(20)  DEFAULT NULL,
  `street`           VARCHAR(150) DEFAULT NULL,
  `title`            VARCHAR(150) DEFAULT NULL,
  `message`          TEXT         DEFAULT NULL,
  `coords`           LONGTEXT     DEFAULT NULL,
  `style`            VARCHAR(60)  DEFAULT NULL,
  `blip_sprite`      INT(11)      NOT NULL DEFAULT 1,
  `blip_color`       INT(11)      NOT NULL DEFAULT 1,
  `blip_use_big`     TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_big_sprite`  INT(11)      NOT NULL DEFAULT 1,
  `blip_big_color`   INT(11)      NOT NULL DEFAULT 1,
  `created_at`       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_dispatch_calls_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_call_assignments` (
  `id`        INT(11)     NOT NULL AUTO_INCREMENT,
  `call_id`   INT(11)     NOT NULL,
  `matricule` VARCHAR(32) NOT NULL,
  `status`    VARCHAR(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dispatch_call_assignments` (`call_id`,`matricule`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_groups` (
  `job`    VARCHAR(60) NOT NULL,
  `groups` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_bracelets` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`    VARCHAR(64)  NOT NULL,
  `name`          VARCHAR(100) DEFAULT NULL,
  `reason`        VARCHAR(255) DEFAULT NULL,
  `description`   TEXT         DEFAULT NULL,
  `palette_index` INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_dispatch_bracelets_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_advanced_records` (
  `id`      INT(11)  NOT NULL AUTO_INCREMENT,
  `payload` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dispatch_advanced_records_citizen` (
  `id`      INT(11)  NOT NULL AUTO_INCREMENT,
  `payload` LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_grade_permissions` (
  `job_name`    VARCHAR(60) NOT NULL,
  `grade`       INT(11)     NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job_name`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_matricules` (
  `identifier` VARCHAR(64) NOT NULL,
  `job_name`   VARCHAR(60) NOT NULL,
  `matricule`  VARCHAR(32) NOT NULL,
  PRIMARY KEY (`identifier`),
  KEY `idx_police_matricules_matricule` (`matricule`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_records` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `record_type`        VARCHAR(60)  NOT NULL,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `citizen_name`       VARCHAR(100) DEFAULT NULL,
  `author_identifier`  VARCHAR(64)  DEFAULT NULL,
  `author_name`        VARCHAR(100) DEFAULT NULL,
  `job_name`           VARCHAR(60)  DEFAULT NULL,
  `title`              VARCHAR(200) DEFAULT NULL,
  `content`            LONGTEXT     DEFAULT NULL,
  `data`               LONGTEXT     DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  `updated_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_records_citizen` (`citizen_identifier`,`record_type`),
  KEY `idx_police_records_author` (`author_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_fine_types` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `label`    VARCHAR(80)  NOT NULL,
  `category` VARCHAR(32)  NOT NULL,
  `amount`   INT(11)      NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_fines` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `target_identifier`  VARCHAR(64)  NOT NULL,
  `officer_identifier` VARCHAR(64)  DEFAULT NULL,
  `officer_name`       VARCHAR(100) DEFAULT NULL,
  `job_name`           VARCHAR(60)  DEFAULT NULL,
  `fine_id`            VARCHAR(60)  DEFAULT NULL,
  `offense`            VARCHAR(200) DEFAULT NULL,
  `category`           VARCHAR(60)  DEFAULT NULL,
  `amount`             BIGINT(20)   NOT NULL DEFAULT 0,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `billing_id`         INT(11)      DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  `paid_at`            DATETIME     DEFAULT NULL,
  `cancelled_at`       DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_fines_target` (`target_identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_warrants` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `citizen_name`       VARCHAR(100) DEFAULT NULL,
  `reason`             VARCHAR(255) DEFAULT NULL,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'open',
  `author_identifier`  VARCHAR(64)  DEFAULT NULL,
  `author_name`        VARCHAR(100) DEFAULT NULL,
  `job_name`           VARCHAR(60)  DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  `updated_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_warrants_citizen` (`citizen_identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_ppa` (
  `identifier` VARCHAR(64)  NOT NULL,
  `label`      VARCHAR(100) DEFAULT NULL,
  `granted_by` VARCHAR(100) DEFAULT NULL,
  `granted_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_announcements` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`          VARCHAR(60)  NOT NULL,
  `title`             VARCHAR(200) NOT NULL,
  `content`           LONGTEXT     DEFAULT NULL,
  `author_identifier` VARCHAR(64)  DEFAULT NULL,
  `author_name`       VARCHAR(100) DEFAULT NULL,
  `created_at`        DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_announcements_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_wanted_notices` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `citizen_name`       VARCHAR(100) DEFAULT NULL,
  `reason`             VARCHAR(255) DEFAULT NULL,
  `author_identifier`  VARCHAR(64)  DEFAULT NULL,
  `author_name`        VARCHAR(100) DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_wanted_vehicles` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `plate`             VARCHAR(12)  NOT NULL,
  `reason`            VARCHAR(255) DEFAULT NULL,
  `author_identifier` VARCHAR(64)  DEFAULT NULL,
  `author_name`       VARCHAR(100) DEFAULT NULL,
  `created_at`        DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_wanted_vehicles_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_cameras` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `label`    VARCHAR(100) NOT NULL,
  `x`        DOUBLE       NOT NULL DEFAULT 0,
  `y`        DOUBLE       NOT NULL DEFAULT 0,
  `z`        DOUBLE       NOT NULL DEFAULT 0,
  `rx`       DOUBLE       NOT NULL DEFAULT 0,
  `ry`       DOUBLE       NOT NULL DEFAULT 0,
  `rz`       DOUBLE       NOT NULL DEFAULT 0,
  `job_name` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_bodycam_recordings` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  DEFAULT NULL,
  `job_name`   VARCHAR(60)  DEFAULT NULL,
  `data`       LONGTEXT     DEFAULT NULL,
  `url`        VARCHAR(500) DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_fingerprint_scans` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `officer_identifier` VARCHAR(64)  DEFAULT NULL,
  `officer_name`       VARCHAR(100) DEFAULT NULL,
  `citizen_identifier` VARCHAR(64)  DEFAULT NULL,
  `citizen_name`       VARCHAR(100) DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_prison_skins` (
  `identifier` VARCHAR(64) NOT NULL,
  `skin`       LONGTEXT    DEFAULT NULL,
  `created_at` DATETIME    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_dispatch_alerts` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `job_name`    VARCHAR(60)  NOT NULL,
  `title`       VARCHAR(150) DEFAULT NULL,
  `message`     TEXT         DEFAULT NULL,
  `code`        VARCHAR(32)  DEFAULT NULL,
  `x`           DOUBLE       NOT NULL DEFAULT 0,
  `y`           DOUBLE       NOT NULL DEFAULT 0,
  `z`           DOUBLE       NOT NULL DEFAULT 0,
  `district`    VARCHAR(100) DEFAULT NULL,
  `author_name` VARCHAR(100) DEFAULT NULL,
  `created_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_police_dispatch_alerts_job` (`job_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `police_mdt_logs` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `job_name`    VARCHAR(60)  DEFAULT NULL,
  `action`      VARCHAR(60)  DEFAULT NULL,
  `details`     LONGTEXT     DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  8. MAIRIE / GOUVERNEMENT / JUSTICE / MEDIAS
-- =====================================================================

CREATE TABLE IF NOT EXISTS `gouv_grade_permissions` (
  `job_name`    VARCHAR(60) NOT NULL,
  `grade`       INT(11)     NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job_name`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_employee_permissions` (
  `identifier`  VARCHAR(64) NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `doj_grade_permissions` (
  `job_name`    VARCHAR(60) NOT NULL,
  `grade`       INT(11)     NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job_name`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_liaison_messages` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `society`           VARCHAR(60)  NOT NULL,
  `sender_identifier` VARCHAR(64)  DEFAULT NULL,
  `sender_name`       VARCHAR(100) DEFAULT NULL,
  `message`           TEXT         DEFAULT NULL,
  `from_gouv`         TINYINT(1)   NOT NULL DEFAULT 0,
  `is_read`           TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_gouv_liaison_messages_soc` (`society`,`from_gouv`,`is_read`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_company_taxes` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `society`    VARCHAR(60)  NOT NULL,
  `label`      VARCHAR(150) NOT NULL,
  `amount`     BIGINT(20)   NOT NULL DEFAULT 0,
  `period`     VARCHAR(32)  DEFAULT NULL,
  `active`     TINYINT(1)   NOT NULL DEFAULT 1,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gouv_company_taxes_society` (`society`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_tax_logs` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `society`      VARCHAR(60)  NOT NULL,
  `label`        VARCHAR(150) DEFAULT NULL,
  `amount`       BIGINT(20)   NOT NULL DEFAULT 0,
  `collected_by` VARCHAR(100) DEFAULT NULL,
  `created_at`   DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gouv_tax_logs_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_society_tax` (
  `society` VARCHAR(60) NOT NULL,
  `rate`    FLOAT       NOT NULL DEFAULT 0,
  `active`  TINYINT(1)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_appointments` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `citizen_name`       VARCHAR(100) DEFAULT NULL,
  `phone`              VARCHAR(20)  DEFAULT NULL,
  `subject`            VARCHAR(200) DEFAULT NULL,
  `note`               TEXT         DEFAULT NULL,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `staff_name`         VARCHAR(100) DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gouv_discussions` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `from_job`          VARCHAR(60)  NOT NULL,
  `to_job`            VARCHAR(60)  NOT NULL,
  `sender_identifier` VARCHAR(64)  DEFAULT NULL,
  `sender_name`       VARCHAR(100) DEFAULT NULL,
  `message`           TEXT         DEFAULT NULL,
  `is_read`           TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`        DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_gouv_discussions_pair` (`from_job`,`to_job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `media_announcements` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `brand`             VARCHAR(60)  NOT NULL,
  `title`             VARCHAR(200) NOT NULL,
  `content`           LONGTEXT     DEFAULT NULL,
  `format`            VARCHAR(32)  DEFAULT NULL,
  `image`             VARCHAR(500) DEFAULT NULL,
  `author_identifier` VARCHAR(64)  DEFAULT NULL,
  `author_name`       VARCHAR(100) DEFAULT NULL,
  `broadcasted`       TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`        DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_media_announcements_brand` (`brand`,`broadcasted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cayo_visas` (
  `identifier` VARCHAR(64)  NOT NULL,
  `granted_by` VARCHAR(100) DEFAULT NULL,
  `granted_at` DATETIME     DEFAULT NULL,
  `expires_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  9. SAMS (hopitaux / medical)
-- =====================================================================

CREATE TABLE IF NOT EXISTS `sams_grade_permissions` (
  `hospital`    VARCHAR(60) NOT NULL,
  `grade`       INT(11)     NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`hospital`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_hospitals` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `pos`          LONGTEXT     DEFAULT NULL,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_hospital_spawns` (
  `id`          INT(11)  NOT NULL AUTO_INCREMENT,
  `hospital_id` INT(11)  NOT NULL,
  `pos`         LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_hospital_spawns` (`hospital_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_pharmacies` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `pos`          LONGTEXT     DEFAULT NULL,
  `npc_pos`      LONGTEXT     DEFAULT NULL,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_pharmacy_items` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(64)  NOT NULL,
  `label`         VARCHAR(100) DEFAULT NULL,
  `price`         INT(11)      NOT NULL DEFAULT 0,
  `is_sams_item`  TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_sams_pharmacy_items` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_reports` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `author_identifier`  VARCHAR(64)  DEFAULT NULL,
  `citizen_identifier` VARCHAR(64)  DEFAULT NULL,
  `title`              VARCHAR(200) DEFAULT NULL,
  `content`            LONGTEXT     DEFAULT NULL,
  `hospital`           VARCHAR(60)  DEFAULT NULL,
  `deleted`            TINYINT(1)   NOT NULL DEFAULT 0,
  `created_at`         DATETIME     DEFAULT NULL,
  `updated_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_reports_hospital` (`hospital`,`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_documents` (
  `id`                 INT(11)     NOT NULL AUTO_INCREMENT,
  `author_identifier`  VARCHAR(64) DEFAULT NULL,
  `citizen_identifier` VARCHAR(64) DEFAULT NULL,
  `type`               VARCHAR(60) DEFAULT NULL,
  `content`            LONGTEXT    DEFAULT NULL,
  `hospital`           VARCHAR(60) DEFAULT NULL,
  `created_at`         DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_documents_hospital` (`hospital`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_announcements` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `author`     VARCHAR(100) DEFAULT NULL,
  `title`      VARCHAR(200) NOT NULL,
  `content`    LONGTEXT     DEFAULT NULL,
  `priority`   VARCHAR(20)  DEFAULT NULL,
  `hospital`   VARCHAR(60)  DEFAULT NULL,
  `created_at` DATETIME     DEFAULT NULL,
  `updated_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_announcements_hospital` (`hospital`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_citizen_notes` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `author`             VARCHAR(100) DEFAULT NULL,
  `note`               TEXT         DEFAULT NULL,
  `created_at`         DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_citizen_notes` (`citizen_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_invoices` (
  `id`                 INT(11)      NOT NULL AUTO_INCREMENT,
  `citizen_identifier` VARCHAR(64)  NOT NULL,
  `created_by`         VARCHAR(100) DEFAULT NULL,
  `hospital`           VARCHAR(60)  DEFAULT NULL,
  `total`              BIGINT(20)   NOT NULL DEFAULT 0,
  `items`              LONGTEXT     DEFAULT NULL,
  `status`             VARCHAR(20)  NOT NULL DEFAULT 'unpaid',
  `date`               DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_invoices_citizen` (`citizen_identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_treatments` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(150) NOT NULL,
  `description` TEXT         DEFAULT NULL,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `hospital`    VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_treatments_hospital` (`hospital`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_procedures` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(150) NOT NULL,
  `description` TEXT         DEFAULT NULL,
  `hospital`    VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_procedures_hospital` (`hospital`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_alerts` (
  `id`                 INT(11)     NOT NULL AUTO_INCREMENT,
  `type`               VARCHAR(60) DEFAULT NULL,
  `description`        TEXT        DEFAULT NULL,
  `citizen_identifier` VARCHAR(64) DEFAULT NULL,
  `coordinates`        LONGTEXT    DEFAULT NULL,
  `state`              VARCHAR(20) NOT NULL DEFAULT 'open',
  `taken_by`           VARCHAR(100) DEFAULT NULL,
  `created_at`         DATETIME    DEFAULT NULL,
  `resolved_at`        DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_backups` (
  `id`                   INT(11)      NOT NULL AUTO_INCREMENT,
  `level`                VARCHAR(20)  DEFAULT NULL,
  `requester_identifier` VARCHAR(64)  DEFAULT NULL,
  `hospital`             VARCHAR(60)  DEFAULT NULL,
  `target_hospital`      VARCHAR(60)  DEFAULT NULL,
  `street`               VARCHAR(150) DEFAULT NULL,
  `coords`               LONGTEXT     DEFAULT NULL,
  `state`                VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `accepted_by`          VARCHAR(100) DEFAULT NULL,
  `created_at`           DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_death_causes` (
  `identifier`  VARCHAR(64) NOT NULL,
  `cause`       VARCHAR(100) DEFAULT NULL,
  `source_text` VARCHAR(255) DEFAULT NULL,
  `died_at`     DATETIME     DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sams_logs` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `hospital`   VARCHAR(60)  DEFAULT NULL,
  `agent`      VARCHAR(100) DEFAULT NULL,
  `action`     VARCHAR(60)  DEFAULT NULL,
  `details`    LONGTEXT     DEFAULT NULL,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_sams_logs_hospital` (`hospital`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  10. ILLEGAL — reglages generiques (cle / valeur)
-- =====================================================================

CREATE TABLE IF NOT EXISTS `atm_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `burglary_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drugdealing_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_territories_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `firework_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jewelry_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whitening_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `supermarket_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gofast_settings` (
  `setting_key`   VARCHAR(60) NOT NULL,
  `setting_value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`setting_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  11. ILLEGAL — armureries, ATM, marche noir
-- =====================================================================

CREATE TABLE IF NOT EXISTS `ammunition_shops` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `pos_x`        DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`        DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`        DOUBLE       NOT NULL DEFAULT 0,
  `pos_h`        DOUBLE       NOT NULL DEFAULT 0,
  `npc_x`        DOUBLE       NOT NULL DEFAULT 0,
  `npc_y`        DOUBLE       NOT NULL DEFAULT 0,
  `npc_z`        DOUBLE       NOT NULL DEFAULT 0,
  `npc_h`        DOUBLE       NOT NULL DEFAULT 0,
  `npc_model`    VARCHAR(60)  DEFAULT NULL,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ammunition_items` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(64)  NOT NULL,
  `label`       VARCHAR(100) DEFAULT NULL,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `category`    VARCHAR(60)  DEFAULT NULL,
  `description` TEXT         DEFAULT NULL,
  `enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_ammunition_items_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `atm_custom_positions` (
  `id`      INT(11)      NOT NULL AUTO_INCREMENT,
  `name`    VARCHAR(100) NOT NULL,
  `x`       DOUBLE       NOT NULL DEFAULT 0,
  `y`       DOUBLE       NOT NULL DEFAULT 0,
  `z`       DOUBLE       NOT NULL DEFAULT 0,
  `heading` DOUBLE       NOT NULL DEFAULT 0,
  `active`  TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `atm_hack_log` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `atm_key`    VARCHAR(80) DEFAULT NULL,
  `identifier` VARCHAR(64) DEFAULT NULL,
  `method`     VARCHAR(32) DEFAULT NULL,
  `jackpot`    TINYINT(1)  NOT NULL DEFAULT 0,
  `success`    TINYINT(1)  NOT NULL DEFAULT 0,
  `amount`     BIGINT(20)  NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blackmarket_locations` (
  `id`     INT(11)    NOT NULL AUTO_INCREMENT,
  `pos_x`  DOUBLE     NOT NULL DEFAULT 0,
  `pos_y`  DOUBLE     NOT NULL DEFAULT 0,
  `pos_z`  DOUBLE     NOT NULL DEFAULT 0,
  `pos_h`  DOUBLE     NOT NULL DEFAULT 0,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blackmarket_items` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `market_id`      INT(11)      NOT NULL,
  `item_name`      VARCHAR(64)  NOT NULL,
  `label`          VARCHAR(100) DEFAULT NULL,
  `price`          INT(11)      NOT NULL DEFAULT 0,
  `stock_quantity` INT(11)      NOT NULL DEFAULT 0,
  `enabled`        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_blackmarket_items` (`market_id`,`item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blackmarket_delivery_spots` (
  `id`      INT(11)      NOT NULL AUTO_INCREMENT,
  `name`    VARCHAR(100) DEFAULT NULL,
  `pos_x`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_h`   DOUBLE       NOT NULL DEFAULT 0,
  `enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blackmarket_deliveries` (
  `id`             INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`     VARCHAR(64) NOT NULL,
  `market_id`      INT(11)     NOT NULL,
  `items`          LONGTEXT    DEFAULT NULL,
  `pos_x`          DOUBLE      NOT NULL DEFAULT 0,
  `pos_y`          DOUBLE      NOT NULL DEFAULT 0,
  `pos_z`          DOUBLE      NOT NULL DEFAULT 0,
  `pos_h`          DOUBLE      NOT NULL DEFAULT 0,
  `status`         VARCHAR(20) NOT NULL DEFAULT 'pending',
  `vehicle_net_id` INT(11)     DEFAULT NULL,
  `expires_at`     DATETIME    DEFAULT NULL,
  `created_at`     TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_blackmarket_deliveries_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  12. ILLEGAL — cambriolage, craft, recolte, transformation
-- =====================================================================

CREATE TABLE IF NOT EXISTS `burglary_interiors` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`     VARCHAR(100) NOT NULL,
  `ipl_name` VARCHAR(100) DEFAULT NULL,
  `spawn_x`  DOUBLE       NOT NULL DEFAULT 0,
  `spawn_y`  DOUBLE       NOT NULL DEFAULT 0,
  `spawn_z`  DOUBLE       NOT NULL DEFAULT 0,
  `spawn_h`  DOUBLE       NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `burglary_houses` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(100) NOT NULL,
  `entry_x`      DOUBLE       NOT NULL DEFAULT 0,
  `entry_y`      DOUBLE       NOT NULL DEFAULT 0,
  `entry_z`      DOUBLE       NOT NULL DEFAULT 0,
  `interior_id`  INT(11)      DEFAULT NULL,
  `active`       TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 0,
  `last_robbed`  BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_burglary_houses_interior` (`interior_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `burglary_loot_points` (
  `id`          INT(11)  NOT NULL AUTO_INCREMENT,
  `interior_id` INT(11)  NOT NULL,
  `pos_x`       DOUBLE   NOT NULL DEFAULT 0,
  `pos_y`       DOUBLE   NOT NULL DEFAULT 0,
  `pos_z`       DOUBLE   NOT NULL DEFAULT 0,
  `loot_table`  LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_burglary_loot_points_interior` (`interior_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_craft_stations` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(100) NOT NULL,
  `station_type`        VARCHAR(60)  NOT NULL DEFAULT 'armes',
  `coords_x`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`            DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`          DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`            DOUBLE       DEFAULT NULL,
  `marker_y`            DOUBLE       DEFAULT NULL,
  `marker_z`            DOUBLE       DEFAULT NULL,
  `prop_model`          VARCHAR(60)  DEFAULT NULL,
  `blip_enabled`        TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`         INT(11)      NOT NULL DEFAULT 1,
  `blip_color`          INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`          FLOAT        NOT NULL DEFAULT 0.5,
  `blip_label`          VARCHAR(100) DEFAULT NULL,
  `faction_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `faction_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_craft_recipes` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `station_id`          INT(11)      NOT NULL,
  `recipe_name`         VARCHAR(100) NOT NULL,
  `label`               VARCHAR(100) DEFAULT NULL,
  `output_item`         VARCHAR(64)  NOT NULL,
  `output_quantity`     INT(11)      NOT NULL DEFAULT 1,
  `ingredients`         LONGTEXT     DEFAULT NULL,
  `craft_time`          INT(11)      NOT NULL DEFAULT 5000,
  `slot_index`          INT(11)      NOT NULL DEFAULT 0,
  `faction_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `faction_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_illegal_craft_recipes_station` (`station_id`,`slot_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_craft_queue` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `station_id`  INT(11)      NOT NULL,
  `recipe_id`   INT(11)      NOT NULL,
  `identifier`  VARCHAR(64)  NOT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 1,
  `status`      VARCHAR(20)  NOT NULL DEFAULT 'queued',
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_illegal_craft_queue_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_static_harvest_spots` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(100) NOT NULL,
  `coords`              LONGTEXT     DEFAULT NULL,
  `item_output`         VARCHAR(64)  DEFAULT NULL,
  `output_quantity`     INT(11)      NOT NULL DEFAULT 1,
  `harvest_time`        INT(11)      NOT NULL DEFAULT 5000,
  `animation_type`      VARCHAR(32)  NOT NULL DEFAULT 'standing',
  `blip_enabled`        TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`         INT(11)      NOT NULL DEFAULT 1,
  `blip_color`          INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`          FLOAT        NOT NULL DEFAULT 0.5,
  `blip_label`          VARCHAR(100) DEFAULT NULL,
  `faction_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `faction_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  `interaction_key`     INT(11)      NOT NULL DEFAULT 38,
  `interaction_text`    VARCHAR(150) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_harvest_spots` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(100) NOT NULL,
  `coords_x`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`            DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`          DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`            DOUBLE       DEFAULT NULL,
  `marker_y`            DOUBLE       DEFAULT NULL,
  `marker_z`            DOUBLE       DEFAULT NULL,
  `prop_model`          VARCHAR(60)  DEFAULT NULL,
  `item_output`         VARCHAR(64)  DEFAULT NULL,
  `output_quantity`     INT(11)      NOT NULL DEFAULT 1,
  `harvest_time`        INT(11)      NOT NULL DEFAULT 5000,
  `cooldown_seconds`    INT(11)      NOT NULL DEFAULT 0,
  `animation_type`      VARCHAR(32)  NOT NULL DEFAULT 'predefined',
  `animation_dict`      VARCHAR(100) DEFAULT NULL,
  `animation_name`      VARCHAR(100) DEFAULT NULL,
  `animation_preset`    VARCHAR(60)  DEFAULT NULL,
  `animation_prop`      VARCHAR(60)  DEFAULT NULL,
  `blip_enabled`        TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`         INT(11)      NOT NULL DEFAULT 1,
  `blip_color`          INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`          FLOAT        NOT NULL DEFAULT 0.5,
  `blip_label`          VARCHAR(100) DEFAULT NULL,
  `faction_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `faction_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `illegal_transform_spots` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                VARCHAR(100) NOT NULL,
  `coords_x`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`            DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`            DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`          DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`            DOUBLE       DEFAULT NULL,
  `marker_y`            DOUBLE       DEFAULT NULL,
  `marker_z`            DOUBLE       DEFAULT NULL,
  `prop_model`          VARCHAR(60)  DEFAULT NULL,
  `input_item`          VARCHAR(64)  DEFAULT NULL,
  `input_quantity`      INT(11)      NOT NULL DEFAULT 1,
  `output_item`         VARCHAR(64)  DEFAULT NULL,
  `output_quantity`     INT(11)      NOT NULL DEFAULT 1,
  `transform_time`      INT(11)      NOT NULL DEFAULT 5000,
  `cooldown_seconds`    INT(11)      NOT NULL DEFAULT 0,
  `animation_type`      VARCHAR(32)  NOT NULL DEFAULT 'predefined',
  `animation_dict`      VARCHAR(100) DEFAULT NULL,
  `animation_name`      VARCHAR(100) DEFAULT NULL,
  `animation_preset`    VARCHAR(60)  DEFAULT NULL,
  `animation_prop`      VARCHAR(60)  DEFAULT NULL,
  `blip_enabled`        TINYINT(1)   NOT NULL DEFAULT 0,
  `blip_sprite`         INT(11)      NOT NULL DEFAULT 1,
  `blip_color`          INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`          FLOAT        NOT NULL DEFAULT 0.5,
  `blip_label`          VARCHAR(100) DEFAULT NULL,
  `faction_restriction` VARCHAR(60)  NOT NULL DEFAULT '',
  `faction_grade_min`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  13. ILLEGAL — deal de drogue, feux d'artifice, braquages
-- =====================================================================

CREATE TABLE IF NOT EXISTS `drugdealing_zones` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `zone_name`        VARCHAR(100) NOT NULL,
  `enabled`          TINYINT(1)   NOT NULL DEFAULT 1,
  `price_multiplier` FLOAT        NOT NULL DEFAULT 1,
  `police_chance`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drugdealing_zones` (`zone_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drugdealing_prices` (
  `id`        INT(11)     NOT NULL AUTO_INCREMENT,
  `item_name` VARCHAR(64) NOT NULL,
  `min_price` INT(11)     NOT NULL DEFAULT 0,
  `max_price` INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_drugdealing_prices` (`item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `drugdealing_sales` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64)  NOT NULL,
  `player_name`  VARCHAR(100) DEFAULT NULL,
  `zone_name`    VARCHAR(100) DEFAULT NULL,
  `item_name`    VARCHAR(64)  DEFAULT NULL,
  `quantity`     INT(11)      NOT NULL DEFAULT 0,
  `amount`       BIGINT(20)   NOT NULL DEFAULT 0,
  `territory_id` INT(11)      DEFAULT NULL,
  `created_at`   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_drugdealing_sales_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `firework_shops` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `name`      VARCHAR(100) NOT NULL,
  `pos_x`     DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`     DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`     DOUBLE       NOT NULL DEFAULT 0,
  `pos_h`     DOUBLE       NOT NULL DEFAULT 0,
  `npc_x`     DOUBLE       NOT NULL DEFAULT 0,
  `npc_y`     DOUBLE       NOT NULL DEFAULT 0,
  `npc_z`     DOUBLE       NOT NULL DEFAULT 0,
  `npc_h`     DOUBLE       NOT NULL DEFAULT 0,
  `npc_model` VARCHAR(60)  DEFAULT NULL,
  `active`    TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `firework_items` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`     VARCHAR(64)  NOT NULL,
  `label`    VARCHAR(100) DEFAULT NULL,
  `price`    INT(11)      NOT NULL DEFAULT 0,
  `category` VARCHAR(60)  DEFAULT NULL,
  `stock`    INT(11)      NOT NULL DEFAULT 0,
  `enabled`  TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_firework_items_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `firework_purchases` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,
  `quantity`   INT(11)     NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_firework_purchases_ident` (`identifier`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `fleeca_banks` (
  `id`                       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                     VARCHAR(100) NOT NULL,
  `pos_x`                    DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`                    DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`                    DOUBLE       NOT NULL DEFAULT 0,
  `active`                   TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled`             TINYINT(1)   NOT NULL DEFAULT 1,
  `can_rob`                  TINYINT(1)   NOT NULL DEFAULT 1,
  `door_hack_x`              DOUBLE       DEFAULT NULL,
  `door_hack_y`              DOUBLE       DEFAULT NULL,
  `door_hack_z`              DOUBLE       DEFAULT NULL,
  `vault_door_x`             DOUBLE       DEFAULT NULL,
  `vault_door_y`             DOUBLE       DEFAULT NULL,
  `vault_door_z`             DOUBLE       DEFAULT NULL,
  `vault_door_model`         VARCHAR(60)  DEFAULT NULL,
  `safe_positions`           LONGTEXT     DEFAULT NULL,
  `account_access_positions` LONGTEXT     DEFAULT NULL,
  `last_robbed`              BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `jewelry_config` (
  `id`               INT(11)  NOT NULL,
  `computer_x`       DOUBLE   NOT NULL DEFAULT 0,
  `computer_y`       DOUBLE   NOT NULL DEFAULT 0,
  `computer_z`       DOUBLE   NOT NULL DEFAULT 0,
  `computer_heading` DOUBLE   NOT NULL DEFAULT 0,
  `display_cases`    LONGTEXT DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pacific_positions` (
  `config_key` VARCHAR(60) NOT NULL,
  `x`          DOUBLE      NOT NULL DEFAULT 0,
  `y`          DOUBLE      NOT NULL DEFAULT 0,
  `z`          DOUBLE      NOT NULL DEFAULT 0,
  `heading`    DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pacific_safes` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `safe_type`  VARCHAR(32) NOT NULL,
  `safe_index` INT(11)     NOT NULL DEFAULT 0,
  `x`          DOUBLE      NOT NULL DEFAULT 0,
  `y`          DOUBLE      NOT NULL DEFAULT 0,
  `z`          DOUBLE      NOT NULL DEFAULT 0,
  `heading`    DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pacific_safes` (`safe_type`,`safe_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pacific_doors` (
  `id`         INT(11) NOT NULL AUTO_INCREMENT,
  `door_index` INT(11) NOT NULL DEFAULT 0,
  `x`          DOUBLE  NOT NULL DEFAULT 0,
  `y`          DOUBLE  NOT NULL DEFAULT 0,
  `z`          DOUBLE  NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pacific_state` (
  `id`             INT(11)     NOT NULL,
  `vault_code`     VARCHAR(32) DEFAULT NULL,
  `entry_code`     VARCHAR(32) DEFAULT NULL,
  `computer_code`  VARCHAR(32) DEFAULT NULL,
  `security_code`  VARCHAR(32) DEFAULT NULL,
  `last_robbed`    BIGINT(20)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `supermarkets` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(100) NOT NULL,
  `store_type`       VARCHAR(60)  DEFAULT NULL,
  `pos_x`            DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`            DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`            DOUBLE       NOT NULL DEFAULT 0,
  `apu_x`            DOUBLE       DEFAULT NULL,
  `apu_y`            DOUBLE       DEFAULT NULL,
  `apu_z`            DOUBLE       DEFAULT NULL,
  `apu_h`            DOUBLE       DEFAULT NULL,
  `safe_x`           DOUBLE       DEFAULT NULL,
  `safe_y`           DOUBLE       DEFAULT NULL,
  `safe_z`           DOUBLE       DEFAULT NULL,
  `safe_h`           DOUBLE       DEFAULT NULL,
  `zone_radius`      FLOAT        NOT NULL DEFAULT 25,
  `active`           TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
  `can_rob`          TINYINT(1)   NOT NULL DEFAULT 1,
  `apu_last_robbed`  BIGINT(20)   NOT NULL DEFAULT 0,
  `safe_last_robbed` BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `supermarket_items` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`     VARCHAR(64)  NOT NULL,
  `label`    VARCHAR(100) DEFAULT NULL,
  `price`    INT(11)      NOT NULL DEFAULT 0,
  `category` VARCHAR(60)  DEFAULT NULL,
  `enabled`  TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_supermarket_items_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gofast_npcs` (
  `id`      INT(11)      NOT NULL AUTO_INCREMENT,
  `region`  VARCHAR(60)  NOT NULL,
  `enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  `pos_x`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`   DOUBLE       NOT NULL DEFAULT 0,
  `heading` DOUBLE       NOT NULL DEFAULT 0,
  `model`   VARCHAR(60)  DEFAULT NULL,
  `label`   VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gofast_categories` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `name`           VARCHAR(60)  NOT NULL,
  `label`          VARCHAR(100) DEFAULT NULL,
  `vehicle_models` LONGTEXT     DEFAULT NULL,
  `price_min`      INT(11)      NOT NULL DEFAULT 0,
  `price_max`      INT(11)      NOT NULL DEFAULT 0,
  `enabled`        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_gofast_categories_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gofast_deliveries` (
  `id`      INT(11)      NOT NULL AUTO_INCREMENT,
  `region`  VARCHAR(60)  NOT NULL,
  `label`   VARCHAR(100) DEFAULT NULL,
  `pos_x`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`   DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`   DOUBLE       NOT NULL DEFAULT 0,
  `enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gofast_missions` (
  `id`               INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`       VARCHAR(64) NOT NULL,
  `region`           VARCHAR(60) DEFAULT NULL,
  `category`         VARCHAR(60) DEFAULT NULL,
  `vehicle_model`    VARCHAR(60) DEFAULT NULL,
  `vehicle_plate`    VARCHAR(12) DEFAULT NULL,
  `vehicle_price`    BIGINT(20)  NOT NULL DEFAULT 0,
  `delivery_x`       DOUBLE      NOT NULL DEFAULT 0,
  `delivery_y`       DOUBLE      NOT NULL DEFAULT 0,
  `delivery_z`       DOUBLE      NOT NULL DEFAULT 0,
  `delivery_region`  VARCHAR(60) DEFAULT NULL,
  `status`           VARCHAR(20) NOT NULL DEFAULT 'running',
  `cancel_reason`    VARCHAR(60) DEFAULT NULL,
  `created_at`       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_gofast_missions_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whitening_points` (
  `id`                       INT(11)      NOT NULL AUTO_INCREMENT,
  `name`                     VARCHAR(100) NOT NULL,
  `pos_x`                    DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`                    DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`                    DOUBLE       NOT NULL DEFAULT 0,
  `active`                   TINYINT(1)   NOT NULL DEFAULT 1,
  `group_restriction`        VARCHAR(60)  DEFAULT NULL,
  `override_max_dirty_money` BIGINT(20)   DEFAULT NULL,
  `override_fee_percent`     FLOAT        DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whitening_quota` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `scope`        VARCHAR(32) NOT NULL,
  `scope_key`    VARCHAR(64) NOT NULL,
  `amount`       BIGINT(20)  NOT NULL DEFAULT 0,
  `period_start` VARCHAR(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_whitening_quota` (`scope`,`scope_key`,`period_start`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `whitening_sessions` (
  `id`             INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`     VARCHAR(64) NOT NULL,
  `point_id`       INT(11)     NOT NULL,
  `dirty_amount`   BIGINT(20)  NOT NULL DEFAULT 0,
  `clean_amount`   BIGINT(20)  NOT NULL DEFAULT 0,
  `fee`            BIGINT(20)  NOT NULL DEFAULT 0,
  `fee_percent`    FLOAT       NOT NULL DEFAULT 0,
  `timer_seconds`  INT(11)     NOT NULL DEFAULT 0,
  `started_at`     BIGINT(20)  NOT NULL DEFAULT 0,
  `status`         VARCHAR(20) NOT NULL DEFAULT 'running',
  PRIMARY KEY (`id`),
  KEY `idx_whitening_sessions_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pochon_shop_config` (
  `id`                  INT(11)    NOT NULL,
  `price`               INT(11)    NOT NULL DEFAULT 0,
  `dirty_money_price`   INT(11)    NOT NULL DEFAULT 0,
  `dirty_money_allowed` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  14. FACTIONS / CREWS / TERRITOIRES / LABOS / KOTH
-- =====================================================================

CREATE TABLE IF NOT EXISTS `crews` (
  `name`       VARCHAR(60)  NOT NULL,
  `label`      VARCHAR(100) NOT NULL,
  `type`       VARCHAR(32)  NOT NULL DEFAULT 'gang',
  `color`      VARCHAR(20)  DEFAULT NULL,
  `activity`   LONGTEXT     DEFAULT NULL,
  `hierarchie` LONGTEXT     DEFAULT NULL,
  `devise`     VARCHAR(255) DEFAULT NULL,
  `place`      INT(11)      NOT NULL DEFAULT 2,
  `xp`         BIGINT(20)   NOT NULL DEFAULT 0,
  `influence`  BIGINT(20)   NOT NULL DEFAULT 0,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `factions` (
  `id`    INT(11)      NOT NULL AUTO_INCREMENT,
  `name`  VARCHAR(60)  NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `color` VARCHAR(20)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_factions_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_meta` (
  `faction_name`        VARCHAR(60)  NOT NULL,
  `motto`               VARCHAR(255) DEFAULT NULL,
  `chest_min_deposit`   INT(11)      NOT NULL DEFAULT 0,
  `chest_min_withdraw`  INT(11)      NOT NULL DEFAULT 0,
  `chest_min_history`   INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`faction_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_grades` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `faction_name` VARCHAR(60)  NOT NULL,
  `name`         VARCHAR(60)  NOT NULL,
  `level`        INT(11)      NOT NULL DEFAULT 0,
  `color`        VARCHAR(20)  NOT NULL DEFAULT '#9e9e9e',
  `permissions`  LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_faction_grades` (`faction_name`,`level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_members` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `faction_name` VARCHAR(60)  NOT NULL,
  `identifier`   VARCHAR(64)  NOT NULL,
  `name`         VARCHAR(100) DEFAULT NULL,
  `grade_level`  INT(11)      NOT NULL DEFAULT 0,
  `joined_at`    DATETIME     DEFAULT NULL,
  `last_seen`    DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_faction_members` (`faction_name`,`identifier`),
  KEY `idx_faction_members_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_recruit_requests` (
  `id`                 INT(11)     NOT NULL AUTO_INCREMENT,
  `faction_name`       VARCHAR(60) NOT NULL,
  `recruiter_perm_id`  VARCHAR(64) DEFAULT NULL,
  `target_perm_id`     VARCHAR(64) DEFAULT NULL,
  `grade_id`           INT(11)     DEFAULT NULL,
  `status`             VARCHAR(20) NOT NULL DEFAULT 'pending',
  `created_at`         TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_faction_recruit_requests` (`faction_name`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_chests` (
  `id`                VARCHAR(100) NOT NULL,
  `faction_name`      VARCHAR(60)  NOT NULL,
  `access_name`       VARCHAR(100) DEFAULT NULL,
  `name`              VARCHAR(100) DEFAULT NULL,
  `grade_min_take`    INT(11)      NOT NULL DEFAULT 0,
  `grade_min_put`     INT(11)      NOT NULL DEFAULT 0,
  `grade_min_history` INT(11)      NOT NULL DEFAULT 0,
  `max_weight`        INT(11)      NOT NULL DEFAULT 100000,
  PRIMARY KEY (`id`),
  KEY `idx_faction_chests_faction` (`faction_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_chest_history` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `chest_id`    VARCHAR(100) NOT NULL,
  `member_id`   VARCHAR(64)  DEFAULT NULL,
  `member_name` VARCHAR(100) DEFAULT NULL,
  `action`      VARCHAR(32)  DEFAULT NULL,
  `item_name`   VARCHAR(64)  DEFAULT NULL,
  `quantity`    INT(11)      NOT NULL DEFAULT 0,
  `date`        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_faction_chest_history_chest` (`chest_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `faction_territories` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `name`           VARCHAR(100) NOT NULL,
  `polygon`        LONGTEXT     DEFAULT NULL,
  `display_number` INT(11)      DEFAULT NULL,
  `display_color`  VARCHAR(20)  DEFAULT NULL,
  `owner`          VARCHAR(60)  DEFAULT NULL,
  `owner_crew`     VARCHAR(60)  DEFAULT NULL,
  `owned_since`    BIGINT(20)   NOT NULL DEFAULT 0,
  `sales_count`    INT(11)      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_faction_territories_owner` (`owner`),
  KEY `idx_faction_territories_crew` (`owner_crew`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_permissions` (
  `crew_name`   VARCHAR(60) NOT NULL,
  `grade_name`  VARCHAR(60) NOT NULL,
  `permissions` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`crew_name`,`grade_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_members` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `crew_name`  VARCHAR(60) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `rank`       INT(11)     NOT NULL DEFAULT 5,
  `xp`         BIGINT(20)  NOT NULL DEFAULT 0,
  `role`       VARCHAR(60) DEFAULT NULL,
  `seniority`  VARCHAR(60) DEFAULT NULL,
  `status`     VARCHAR(20) NOT NULL DEFAULT 'offline',
  `joined_at`  DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crew_members_identifier` (`identifier`),
  KEY `idx_crew_members_crew` (`crew_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_activities` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `crew_name`  VARCHAR(60) NOT NULL,
  `identifier` VARCHAR(64) NOT NULL,
  `activity`   VARCHAR(60) NOT NULL,
  `score`      BIGINT(20)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_crew_activities` (`crew_name`,`identifier`,`activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_craft_recipes` (
  `id`        INT(11)     NOT NULL AUTO_INCREMENT,
  `crew_name` VARCHAR(60) NOT NULL,
  `recipe`    LONGTEXT    DEFAULT NULL,
  `min_rank`  INT(11)     NOT NULL DEFAULT 5,
  PRIMARY KEY (`id`),
  KEY `idx_crew_craft_recipes_crew` (`crew_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_properties` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `crew_name`   VARCHAR(60)  NOT NULL,
  `property_id` INT(11)      DEFAULT NULL,
  `label`       VARCHAR(150) DEFAULT NULL,
  `address`     VARCHAR(150) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_crew_properties_crew` (`crew_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `crew_vehicles` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `crew_name` VARCHAR(60)  NOT NULL,
  `plate`     VARCHAR(12)  DEFAULT NULL,
  `model`     VARCHAR(60)  DEFAULT NULL,
  `label`     VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_crew_vehicles_crew` (`crew_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labos` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `name`              VARCHAR(100) NOT NULL,
  `label`             VARCHAR(100) DEFAULT NULL,
  `owner_faction`     VARCHAR(60)  DEFAULT NULL,
  `door_x`            DOUBLE       NOT NULL DEFAULT 0,
  `door_y`            DOUBLE       NOT NULL DEFAULT 0,
  `door_z`            DOUBLE       NOT NULL DEFAULT 0,
  `door_heading`      DOUBLE       NOT NULL DEFAULT 0,
  `interior_x`        DOUBLE       NOT NULL DEFAULT 0,
  `interior_y`        DOUBLE       NOT NULL DEFAULT 0,
  `interior_z`        DOUBLE       NOT NULL DEFAULT 0,
  `interior_heading`  DOUBLE       NOT NULL DEFAULT 0,
  `chest_x`           DOUBLE       DEFAULT NULL,
  `chest_y`           DOUBLE       DEFAULT NULL,
  `chest_z`           DOUBLE       DEFAULT NULL,
  `chest_max_slots`   INT(11)      NOT NULL DEFAULT 40,
  `management_x`      DOUBLE       DEFAULT NULL,
  `management_y`      DOUBLE       DEFAULT NULL,
  `management_z`      DOUBLE       DEFAULT NULL,
  `blip_sprite`       INT(11)      NOT NULL DEFAULT 1,
  `blip_color`        INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`        FLOAT        NOT NULL DEFAULT 0.5,
  `bucket_id`         INT(11)      NOT NULL DEFAULT 0,
  `last_attacked`     BIGINT(20)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labo_access` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `labo_id`           INT(11)      NOT NULL,
  `access_type`       VARCHAR(20)  NOT NULL DEFAULT 'player',
  `player_identifier` VARCHAR(64)  DEFAULT NULL,
  `player_name`       VARCHAR(100) DEFAULT NULL,
  `faction_name`      VARCHAR(60)  DEFAULT NULL,
  `faction_label`     VARCHAR(100) DEFAULT NULL,
  `chest_access`      TINYINT(1)   NOT NULL DEFAULT 0,
  `management_access` TINYINT(1)   NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_labo_access_labo` (`labo_id`,`access_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labo_harvest_points` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `labo_id`          INT(11)      NOT NULL,
  `label`            VARCHAR(100) DEFAULT NULL,
  `coords_x`         DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`         DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`         DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`       DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`         DOUBLE       DEFAULT NULL,
  `marker_y`         DOUBLE       DEFAULT NULL,
  `marker_z`         DOUBLE       DEFAULT NULL,
  `prop_model`       VARCHAR(60)  DEFAULT NULL,
  `item_output`      VARCHAR(64)  DEFAULT NULL,
  `output_quantity`  INT(11)      NOT NULL DEFAULT 1,
  `harvest_time`     INT(11)      NOT NULL DEFAULT 5000,
  `cooldown_seconds` INT(11)      NOT NULL DEFAULT 0,
  `animation_type`   VARCHAR(32)  NOT NULL DEFAULT 'predefined',
  `animation_dict`   VARCHAR(100) DEFAULT NULL,
  `animation_name`   VARCHAR(100) DEFAULT NULL,
  `animation_preset` VARCHAR(60)  DEFAULT NULL,
  `animation_prop`   VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_labo_harvest_points_labo` (`labo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labo_transform_points` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `labo_id`          INT(11)      NOT NULL,
  `label`            VARCHAR(100) DEFAULT NULL,
  `coords_x`         DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`         DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`         DOUBLE       NOT NULL DEFAULT 0,
  `rotation_z`       DOUBLE       NOT NULL DEFAULT 0,
  `marker_x`         DOUBLE       DEFAULT NULL,
  `marker_y`         DOUBLE       DEFAULT NULL,
  `marker_z`         DOUBLE       DEFAULT NULL,
  `prop_model`       VARCHAR(60)  DEFAULT NULL,
  `input_item`       VARCHAR(64)  DEFAULT NULL,
  `input_quantity`   INT(11)      NOT NULL DEFAULT 1,
  `output_item`      VARCHAR(64)  DEFAULT NULL,
  `output_quantity`  INT(11)      NOT NULL DEFAULT 1,
  `transform_time`   INT(11)      NOT NULL DEFAULT 5000,
  `cooldown_seconds` INT(11)      NOT NULL DEFAULT 0,
  `animation_type`   VARCHAR(32)  NOT NULL DEFAULT 'predefined',
  `animation_dict`   VARCHAR(100) DEFAULT NULL,
  `animation_name`   VARCHAR(100) DEFAULT NULL,
  `animation_preset` VARCHAR(60)  DEFAULT NULL,
  `animation_prop`   VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_labo_transform_points_labo` (`labo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labo_stats` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `labo_id`    INT(11)     NOT NULL,
  `action`     VARCHAR(32) NOT NULL,
  `identifier` VARCHAR(64) DEFAULT NULL,
  `item_name`  VARCHAR(64) DEFAULT NULL,
  `quantity`   INT(11)     NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_labo_stats_labo` (`labo_id`,`action`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `labo_attacks` (
  `id`                INT(11)     NOT NULL AUTO_INCREMENT,
  `labo_id`           INT(11)     NOT NULL,
  `attacker_faction`  VARCHAR(60) DEFAULT NULL,
  `defender_faction`  VARCHAR(60) DEFAULT NULL,
  `progress`          INT(11)     NOT NULL DEFAULT 0,
  `success`           TINYINT(1)  NOT NULL DEFAULT 0,
  `started_at`        TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at`          DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_labo_attacks_labo` (`labo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `koth_zones` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `name`             VARCHAR(100) NOT NULL,
  `x`                DOUBLE       NOT NULL DEFAULT 0,
  `y`                DOUBLE       NOT NULL DEFAULT 0,
  `z`                DOUBLE       NOT NULL DEFAULT 0,
  `radius`           FLOAT        NOT NULL DEFAULT 50,
  `duration`         INT(11)      NOT NULL DEFAULT 600,
  `enabled`          TINYINT(1)   NOT NULL DEFAULT 1,
  `schedule_hours`   LONGTEXT     DEFAULT NULL,
  `schedule_start`   VARCHAR(10)  DEFAULT NULL,
  `schedule_finish`  VARCHAR(10)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `koth_history` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `zone_id`        INT(11)      NOT NULL,
  `zone_name`      VARCHAR(100) DEFAULT NULL,
  `winner_faction` VARCHAR(60)  DEFAULT NULL,
  `winner_score`   INT(11)      NOT NULL DEFAULT 0,
  `started_at`     DATETIME     DEFAULT NULL,
  `ended_at`       DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  15. BOUTIQUE / PAIDSHOP / VIP / RECOMPENSES
-- =====================================================================

CREATE TABLE IF NOT EXISTS `paidshop_accounts` (
  `identifier` VARCHAR(64) NOT NULL,
  `unique_id`  VARCHAR(32) DEFAULT NULL,
  `spacecoins` INT(11)     NOT NULL DEFAULT 0,
  `vip_tier`   TINYINT(4)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`),
  UNIQUE KEY `uk_paidshop_accounts_uid` (`unique_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_items` (
  `id`             INT(11)      NOT NULL AUTO_INCREMENT,
  `category`       VARCHAR(60)  NOT NULL,
  `spawn_name`     VARCHAR(100) NOT NULL,
  `name`           VARCHAR(150) DEFAULT NULL,
  `price`          INT(11)      NOT NULL DEFAULT 0,
  `original_price` INT(11)      NOT NULL DEFAULT 0,
  `image`          VARCHAR(500) DEFAULT NULL,
  `tags`           LONGTEXT     DEFAULT NULL,
  `description`    TEXT         DEFAULT NULL,
  `rarity`         VARCHAR(32)  DEFAULT NULL,
  `content`        LONGTEXT     DEFAULT NULL,
  `extra`          LONGTEXT     DEFAULT NULL,
  `enabled`        TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_paidshop_items` (`category`,`spawn_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_purchases` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `category`   VARCHAR(60)  DEFAULT NULL,
  `item_name`  VARCHAR(150) DEFAULT NULL,
  `quantity`   INT(11)      NOT NULL DEFAULT 1,
  `price`      INT(11)      NOT NULL DEFAULT 0,
  `gifted_to`  VARCHAR(64)  DEFAULT NULL,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_paidshop_purchases_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_pending_items` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `category`   VARCHAR(60)  DEFAULT NULL,
  `spawn_name` VARCHAR(100) DEFAULT NULL,
  `name`       VARCHAR(150) DEFAULT NULL,
  `image`      VARCHAR(500) DEFAULT NULL,
  `quantity`   INT(11)      NOT NULL DEFAULT 1,
  `price`      INT(11)      NOT NULL DEFAULT 0,
  `status`     VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `claimed_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_paidshop_pending_items` (`identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_daily_claims` (
  `identifier`               VARCHAR(64) NOT NULL,
  `streak_day`               INT(11)     NOT NULL DEFAULT 0,
  `last_claim_at`            DATETIME    DEFAULT NULL,
  `wheel_classic_claimed_at` DATETIME    DEFAULT NULL,
  `wheel_vip_claimed_at`     DATETIME    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_cases` (
  `id`          INT(11)     NOT NULL AUTO_INCREMENT,
  `case_id`     VARCHAR(60) NOT NULL,
  `content`     LONGTEXT    DEFAULT NULL,
  `revealed`    TINYINT(1)  NOT NULL DEFAULT 0,
  `revealed_by` VARCHAR(64) DEFAULT NULL,
  `sold`        TINYINT(1)  NOT NULL DEFAULT 0,
  `created_at`  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_paidshop_cases` (`case_id`,`sold`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `paidshop_analytics` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `event_type`  VARCHAR(60)  DEFAULT NULL,
  `category`    VARCHAR(60)  DEFAULT NULL,
  `item_name`   VARCHAR(150) DEFAULT NULL,
  `price`       INT(11)      DEFAULT NULL,
  `fail_reason` VARCHAR(150) DEFAULT NULL,
  `created_at`  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boutique_vcoins` (
  `identifier` VARCHAR(64) NOT NULL,
  `vcoins`     INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boutique_purchases` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  NOT NULL,
  `kind`       VARCHAR(32)  DEFAULT NULL,
  `item`       VARCHAR(100) DEFAULT NULL,
  `price`      INT(11)      NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_boutique_purchases_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boutique_packs` (
  `id`        INT(11)      NOT NULL AUTO_INCREMENT,
  `pack_name` VARCHAR(100) NOT NULL,
  `label`     VARCHAR(150) DEFAULT NULL,
  `price`     INT(11)      NOT NULL DEFAULT 0,
  `content`   LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_boutique_packs` (`pack_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boutique_weapons` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `weapon_name` VARCHAR(100) NOT NULL,
  `label`       VARCHAR(150) DEFAULT NULL,
  `type`        VARCHAR(32)  DEFAULT NULL,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `content`     LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_boutique_weapons` (`weapon_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `boutique_vehicles` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `model`    VARCHAR(60)  NOT NULL,
  `label`    VARCHAR(150) DEFAULT NULL,
  `price`    INT(11)      NOT NULL DEFAULT 0,
  `type`     VARCHAR(32)  DEFAULT NULL,
  `category` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_boutique_vehicles_model` (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_tier_config` (
  `tier`                     TINYINT(4) NOT NULL,
  `monthlyCoins`             INT(11)    DEFAULT NULL,
  `hourlyCoins`              INT(11)    DEFAULT NULL,
  `inventoryWeight`          INT(11)    DEFAULT NULL,
  `stateAid`                 INT(11)    DEFAULT NULL,
  `impoundDiscount`          FLOAT      DEFAULT NULL,
  `trunkBonus`               INT(11)    DEFAULT NULL,
  `dynastyBonus`             FLOAT      DEFAULT NULL,
  `propsPermanent`           INT(11)    DEFAULT NULL,
  `propsTemporary`           INT(11)    DEFAULT NULL,
  `respawnTime`              INT(11)    DEFAULT NULL,
  `interimMultiplier`        FLOAT      DEFAULT NULL,
  `gofastMultiplier`         FLOAT      DEFAULT NULL,
  `drugDealingMultiplier`    FLOAT      DEFAULT NULL,
  `ppaLeger`                 TINYINT(1) DEFAULT NULL,
  `ppaLourd`                 TINYINT(1) DEFAULT NULL,
  `plate_changes_per_month`  INT(11)    DEFAULT NULL,
  `driftMode`                TINYINT(1) DEFAULT NULL,
  `weaponCustomization`      TINYINT(1) DEFAULT NULL,
  `freecam`                  TINYINT(1) DEFAULT NULL,
  `emergency_vehicle_model`  VARCHAR(60)  DEFAULT NULL,
  `emergency_vehicle_label`  VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_ppa` (
  `identifier`  VARCHAR(64) NOT NULL,
  `type`        VARCHAR(32) NOT NULL,
  `issued_at`   DATETIME    DEFAULT NULL,
  `valid_until` DATETIME    DEFAULT NULL,
  PRIMARY KEY (`identifier`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_plate_changes` (
  `identifier` VARCHAR(64) NOT NULL,
  `period`     VARCHAR(16) NOT NULL,
  `used`       INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`,`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_monthly_vehicles` (
  `id`               INT(11)      NOT NULL AUTO_INCREMENT,
  `tier`             TINYINT(4)   NOT NULL DEFAULT 1,
  `period`           VARCHAR(16)  DEFAULT NULL,
  `vehicle_model`    VARCHAR(60)  NOT NULL,
  `vehicle_label`    VARCHAR(100) DEFAULT NULL,
  `vehicle_category` VARCHAR(60)  DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_vip_monthly_vehicles` (`tier`,`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `vip_monthly_claims` (
  `id`            INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`    VARCHAR(64) NOT NULL,
  `period`        VARCHAR(16) NOT NULL,
  `vehicle_model` VARCHAR(60) DEFAULT NULL,
  `claimed_at`    DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_vip_monthly_claims` (`identifier`,`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rewards_progress` (
  `identifier`               VARCHAR(64) NOT NULL,
  `last_gift_timestamp`      BIGINT(20)  NOT NULL DEFAULT 0,
  `last_gift_index`          INT(11)     NOT NULL DEFAULT 0,
  `last_vip_gift_timestamp`  BIGINT(20)  NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rewards_history` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,
  `track`      VARCHAR(32) DEFAULT NULL,
  `gift_index` INT(11)     NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rewards_history_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  16. AFK / RECOMPENSES DE PRESENCE
-- =====================================================================

CREATE TABLE IF NOT EXISTS `afk_points` (
  `identifier`    VARCHAR(64) NOT NULL,
  `points`        BIGINT(20)  NOT NULL DEFAULT 0,
  `total_minutes` BIGINT(20)  NOT NULL DEFAULT 0,
  `updated_at`    DATETIME    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `afk_sessions` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64) NOT NULL,
  `bucket`       INT(11)     NOT NULL DEFAULT 0,
  `entered_at`   DATETIME    DEFAULT NULL,
  `exited_at`    DATETIME    DEFAULT NULL,
  `prev_x`       DOUBLE      NOT NULL DEFAULT 0,
  `prev_y`       DOUBLE      NOT NULL DEFAULT 0,
  `prev_z`       DOUBLE      NOT NULL DEFAULT 0,
  `prev_heading` DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_afk_sessions_ident` (`identifier`,`exited_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `afk_shop_cases` (
  `case_id`     VARCHAR(60)  NOT NULL,
  `item_name`   VARCHAR(64)  DEFAULT NULL,
  `name`        VARCHAR(150) DEFAULT NULL,
  `description` TEXT         DEFAULT NULL,
  `price`       INT(11)      NOT NULL DEFAULT 0,
  `image`       VARCHAR(500) DEFAULT NULL,
  `prizes`      LONGTEXT     DEFAULT NULL,
  PRIMARY KEY (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `afk_shop_purchases` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) NOT NULL,
  `case_id`    VARCHAR(60) NOT NULL,
  `prize`      LONGTEXT    DEFAULT NULL,
  `created_at` DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_afk_shop_purchases_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  17. INTERIM / TAXI / DVM (permis)
-- =====================================================================

CREATE TABLE IF NOT EXISTS `interim_jobs` (
  `id`          VARCHAR(60)  NOT NULL,
  `label`       VARCHAR(100) NOT NULL,
  `image`       VARCHAR(255) DEFAULT NULL,
  `description` TEXT         DEFAULT NULL,
  `meta`        LONGTEXT     DEFAULT NULL,
  `sort_order`  INT(11)      NOT NULL DEFAULT 0,
  `enabled`     TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `interim_jobs_center` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `model`        VARCHAR(60)  NOT NULL,
  `x`            DOUBLE       NOT NULL DEFAULT 0,
  `y`            DOUBLE       NOT NULL DEFAULT 0,
  `z`            DOUBLE       NOT NULL DEFAULT 0,
  `heading`      DOUBLE       NOT NULL DEFAULT 0,
  `label`        VARCHAR(100) DEFAULT NULL,
  `blip_enabled` TINYINT(1)   NOT NULL DEFAULT 1,
  `blip_sprite`  INT(11)      NOT NULL DEFAULT 1,
  `blip_scale`   FLOAT        NOT NULL DEFAULT 0.5,
  `blip_color`   INT(11)      NOT NULL DEFAULT 1,
  `blip_name`    VARCHAR(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `interim_job_positions` (
  `job`  VARCHAR(60) NOT NULL,
  `data` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `interim_job_config` (
  `job`  VARCHAR(60) NOT NULL,
  `data` LONGTEXT    DEFAULT NULL,
  PRIMARY KEY (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `interim_player_state` (
  `identifier` VARCHAR(64) NOT NULL,
  `job`        VARCHAR(60) DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxi_enabled_base_zones` (
  `society`  VARCHAR(60) NOT NULL,
  `zone_key` VARCHAR(60) NOT NULL,
  PRIMARY KEY (`society`,`zone_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxi_spawn_zones` (
  `id`      INT(11)     NOT NULL AUTO_INCREMENT,
  `society` VARCHAR(60) NOT NULL,
  `x`       DOUBLE      NOT NULL DEFAULT 0,
  `y`       DOUBLE      NOT NULL DEFAULT 0,
  `z`       DOUBLE      NOT NULL DEFAULT 0,
  `radius`  FLOAT       NOT NULL DEFAULT 50,
  PRIMARY KEY (`id`),
  KEY `idx_taxi_spawn_zones_society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxi_rides` (
  `id`                INT(11)      NOT NULL AUTO_INCREMENT,
  `request_id`        VARCHAR(64)  NOT NULL,
  `client_identifier` VARCHAR(64)  DEFAULT NULL,
  `client_name`       VARCHAR(100) DEFAULT NULL,
  `client_phone`      VARCHAR(20)  DEFAULT NULL,
  `driver_identifier` VARCHAR(64)  DEFAULT NULL,
  `driver_name`       VARCHAR(100) DEFAULT NULL,
  `driver_phone`      VARCHAR(20)  DEFAULT NULL,
  `society`           VARCHAR(60)  DEFAULT NULL,
  `pos_x`             DOUBLE       NOT NULL DEFAULT 0,
  `pos_y`             DOUBLE       NOT NULL DEFAULT 0,
  `pos_z`             DOUBLE       NOT NULL DEFAULT 0,
  `status`            VARCHAR(20)  NOT NULL DEFAULT 'pending',
  `accepted_at`       DATETIME     DEFAULT NULL,
  `started_at`        DATETIME     DEFAULT NULL,
  `finished_at`       DATETIME     DEFAULT NULL,
  `created_at`        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_taxi_rides_request` (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `taxi_npc_rides` (
  `id`              INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`      VARCHAR(64) NOT NULL,
  `society`         VARCHAR(60) DEFAULT NULL,
  `distance`        FLOAT       NOT NULL DEFAULT 0,
  `total_fare`      BIGINT(20)  NOT NULL DEFAULT 0,
  `penalty_percent` FLOAT       NOT NULL DEFAULT 0,
  `penalty_amount`  BIGINT(20)  NOT NULL DEFAULT 0,
  `player_cut`      BIGINT(20)  NOT NULL DEFAULT 0,
  `company_cut`     BIGINT(20)  NOT NULL DEFAULT 0,
  `created_at`      TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_taxi_npc_rides_ident` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dvm_licenses` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64) NOT NULL,
  `char_id`      INT(11)     DEFAULT NULL,
  `license_type` VARCHAR(60) NOT NULL,
  `score`        INT(11)     NOT NULL DEFAULT 0,
  `obtained_at`  DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dvm_licenses` (`identifier`,`license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dvm_exam_history` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64) NOT NULL,
  `char_id`      INT(11)     DEFAULT NULL,
  `exam_type`    VARCHAR(60) DEFAULT NULL,
  `license_type` VARCHAR(60) DEFAULT NULL,
  `score`        INT(11)     NOT NULL DEFAULT 0,
  `passed`       TINYINT(1)  NOT NULL DEFAULT 0,
  `bribed`       TINYINT(1)  NOT NULL DEFAULT 0,
  `created_at`   DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_dvm_exam_history_ident` (`identifier`,`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `dvm_code_passed` (
  `id`           INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier`   VARCHAR(64) NOT NULL,
  `license_type` VARCHAR(60) NOT NULL,
  `score`        INT(11)     NOT NULL DEFAULT 0,
  `created_at`   DATETIME    DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_dvm_code_passed` (`identifier`,`license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  18. STATIONS-SERVICE
-- =====================================================================

CREATE TABLE IF NOT EXISTS `gas_station_settings` (
  `key`   VARCHAR(60) NOT NULL,
  `value` TEXT        DEFAULT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gas_stations` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `name`       VARCHAR(100) NOT NULL,
  `coords_x`   DOUBLE       NOT NULL DEFAULT 0,
  `coords_y`   DOUBLE       NOT NULL DEFAULT 0,
  `coords_z`   DOUBLE       NOT NULL DEFAULT 0,
  `blip_x`     DOUBLE       DEFAULT NULL,
  `blip_y`     DOUBLE       DEFAULT NULL,
  `blip_z`     DOUBLE       DEFAULT NULL,
  `created_by` VARCHAR(64)  DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gas_station_pumps` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `station_id` INT(11)     NOT NULL,
  `coords_x`   DOUBLE      NOT NULL DEFAULT 0,
  `coords_y`   DOUBLE      NOT NULL DEFAULT 0,
  `coords_z`   DOUBLE      NOT NULL DEFAULT 0,
  `model`      VARCHAR(60) DEFAULT NULL,
  `heading`    DOUBLE      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_gas_station_pumps_station` (`station_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `gas_station_logs` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64) DEFAULT NULL,
  `station_id` INT(11)     DEFAULT NULL,
  `liters`     FLOAT       NOT NULL DEFAULT 0,
  `amount`     BIGINT(20)  NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================================
--  19. LOGS, ANTICHEAT & DIVERS
-- =====================================================================

CREATE TABLE IF NOT EXISTS `logs_staff` (
  `id`        INT(11)     NOT NULL AUTO_INCREMENT,
  `source_id` INT(11)     DEFAULT NULL,
  `char_id`   INT(11)     DEFAULT NULL,
  `action`    VARCHAR(60) NOT NULL,
  `payload`   LONGTEXT    DEFAULT NULL,
  `created_at` TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_logs_staff_action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `logs_death` (
  `id`                   INT(11)      NOT NULL AUTO_INCREMENT,
  `char_id`              INT(11)      DEFAULT NULL,
  `source_id`            INT(11)      DEFAULT NULL,
  `victim_coords`        LONGTEXT     DEFAULT NULL,
  `killer_coords`        LONGTEXT     DEFAULT NULL,
  `killer_server_id`     INT(11)      DEFAULT NULL,
  `death_cause`          VARCHAR(100) DEFAULT NULL,
  `computed_cause`       VARCHAR(100) DEFAULT NULL,
  `bone_part`            VARCHAR(60)  DEFAULT NULL,
  `is_headshot`          TINYINT(1)   NOT NULL DEFAULT 0,
  `distance`             FLOAT        NOT NULL DEFAULT 0,
  `status_damage_source` VARCHAR(100) DEFAULT NULL,
  `death_override`       VARCHAR(100) DEFAULT NULL,
  `killed_by_player`     TINYINT(1)   NOT NULL DEFAULT 0,
  `victim_context`       LONGTEXT     DEFAULT NULL,
  `killer_context`       LONGTEXT     DEFAULT NULL,
  `created_at`           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_logs_death_char` (`char_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `anticheat_bans` (
  `id`          INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier`  VARCHAR(64)  DEFAULT NULL,
  `license`     VARCHAR(100) DEFAULT NULL,
  `player_name` VARCHAR(100) DEFAULT NULL,
  `reason`      VARCHAR(255) DEFAULT NULL,
  `kind`        VARCHAR(60)  DEFAULT NULL,
  `created_at`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_anticheat_bans_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `anticheat_attach_reports` (
  `id`                  INT(11)      NOT NULL AUTO_INCREMENT,
  `net_id`              INT(11)      DEFAULT NULL,
  `model`               VARCHAR(60)  DEFAULT NULL,
  `victim_identifier`   VARCHAR(64)  DEFAULT NULL,
  `victim_source`       INT(11)      DEFAULT NULL,
  `attacker_identifier` VARCHAR(64)  DEFAULT NULL,
  `attacker_source`     INT(11)      DEFAULT NULL,
  `attacker_name`       VARCHAR(100) DEFAULT NULL,
  `distance`            FLOAT        NOT NULL DEFAULT 0,
  `outcome`             VARCHAR(60)  DEFAULT NULL,
  `created_at`          DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `rockford_recordings` (
  `id`         INT(11)      NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(64)  DEFAULT NULL,
  `char_id`    INT(11)      DEFAULT NULL,
  `filename`   VARCHAR(255) DEFAULT NULL,
  `payload`    LONGTEXT     DEFAULT NULL,
  `url`        VARCHAR(500) DEFAULT NULL,
  `created_at` DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `scam_computer_data` (
  `identifier` VARCHAR(64) NOT NULL,
  `data`       LONGTEXT    DEFAULT NULL,
  `updated_at` DATETIME    DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
--  FIN DU SCHEMA
-- =====================================================================
