fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'updater'
description 'Mise à jour de la base : `update` en console vérifie, update.bat / update.sh (racine du serveur) applique'
version '3.0.0'

server_script 'server.lua'

-- Convars (server.cfg) :
--   set update_url "https://…"          racine HTTP contenant manifest.json, manifest.txt et files/…
--   set update_check_on_start "true"    signale une nouvelle version au démarrage (un seul appel HTTP)
