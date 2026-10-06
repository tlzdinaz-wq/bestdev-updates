# Best Dev — v1.12.56

**AFK : protection et reprise** — Protection contre les dégâts dès l’entrée en AFK, interruption des pertes de vie par faim/soif et protection retirée à la sortie. Reprise de la session après déconnexion ou reboot du serveur, sans attribuer de points pendant la déconnexion.

**Timer AFK** — Nouvelle interface harmonisée avec le HUD ; le navigateur fait avancer le chronomètre sans envoi NUI à chaque frame.

**Configuration du serveur** — Le nom, les couleurs et le lien Discord sont sauvegardés dans config/branding_overrides.json, puis relus au démarrage. Les anciennes valeurs SQL ne remplacent plus le JSON ; une écriture non confirmée n’est pas annoncée comme réussie. Les configurations personnelles ne sont pas incluses dans cette archive.

**Tablette entreprise** — Correction de l’ouverture et du chargement initial de l’interface, avec normalisation des listes Lua vides pour éviter un écran invisible.

**Mode staff / noclip** — Quitter le mode staff coupe immédiatement le noclip et restaure les propriétés du personnage et du véhicule.

**Nouveaux arrivants** — Indication NEW fondée sur le temps de jeu cumulé, retirée après plus d’une heure et conservant le cumul après reconnexion.

**Menus et animations** — Ajustements de l’ouverture des menus et de leurs effets visuels ; sélection d’une animation avec réponse NUI immédiate et état local isolé.

Pour appliquer : update.bat / ./update.sh (hébergeur : archive ZIP par FTP), puis redémarrage du serveur. Les tests locaux sont validés ; les comportements restent à vérifier en jeu.
