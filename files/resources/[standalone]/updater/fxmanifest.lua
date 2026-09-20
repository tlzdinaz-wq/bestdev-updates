fx_version 'cerulean'
game 'gta5'

name 'updater'
description 'Mise à jour de la base depuis la console : update / update check / update force / update restart'
version '1.0.0'

server_script 'server.js'

-- Convars (server.cfg) :
--   set update_url "https://…"   racine HTTP contenant manifest.json et files/…
