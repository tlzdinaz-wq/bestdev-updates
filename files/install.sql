-- =====================================================================
--  AVREX — installation SQL
--  Nom de la base : `avrex`
--
--  Ce fichier crée uniquement la base. Le schéma complet est dans
--  `avrex.sql` (tables core / EVE). Importe `avrex.sql` ensuite, ou
--  uniquement `avrex.sql` : il crée aussi `avrex` et l'utilise.
--
--  Import :
--     mysql -u root -p < avrex.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `avrex`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `avrex`;
