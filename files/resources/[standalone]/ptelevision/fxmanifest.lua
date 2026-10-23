fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ptelevision'
description 'Lecture de videos (YouTube ou fichier) sur les televisions du monde'
version '1.0.0'

-- Remplace la ressource externe du meme nom : memes evenements et memes exports que ceux
-- appeles par core (menu contextuel d'une television, controleur video, builder Television).

shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

-- Page affichee dans le DUI colle sur l'ecran : nui://ptelevision/html/player.html
files {
    'html/player.html',
}
