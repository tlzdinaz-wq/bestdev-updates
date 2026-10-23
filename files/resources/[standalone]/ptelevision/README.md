# ptelevision

Lit une vidéo YouTube (ou un fichier .mp4 / .webm) sur les télévisions du monde.

Cette ressource remplace la ressource externe du même nom : elle répond aux mêmes évènements et aux mêmes exports que ceux appelés par `core` (menu contextuel d'une télévision, barre de contrôle vidéo, builder Télévision). `core` n'a pas été modifié, à une exception : il expose `TelevisionModels`, la liste du builder.

## Utilisation

- **Lancer** : clic droit sur une télévision (à moins de 25 m) > Télévision > Mettre une vidéo, puis coller le lien.
- **Contrôler** : Télévision > Gérer la vidéo ouvre la barre (pause, avance). Visible seulement quand une vidéo joue.
- **Volume** : Télévision > Gérer le volume. Réglage propre au joueur. Le son baisse avec la distance, jusqu'à la « portée son » du modèle.
- **Arrêter** : Télévision > Arrêter la vidéo.
- **Modèles de télévision** : Gestion > Builder > Télévision (modèle, render target, portée du son, volume, résolution). Un modèle absent de la liste n'a pas de menu Télévision.

Liens acceptés : `youtube.com/watch?v=…` (avec `&t=1m30s`), `youtu.be/…`, `/shorts/`, `/embed/`, `/live/`, un identifiant seul, et un lien direct vers un fichier `.mp4`, `.webm`, `.ogv`, `.m4v`, `.mov`.

## Fonctionnement

Le serveur garde l'état de chaque écran allumé (vidéo, position, pause) et le renvoie aux joueurs de la même instance (les appartements ont chacun la leur). Chaque client dessine la vidéo lui-même : un navigateur hors écran (DUI, page `html/player.html`) lit la vidéo, et son image est copiée chaque image dans le render target du modèle de télévision.

## Limites

- **Un seul écran à la fois par joueur, le plus proche, à moins de 60 m.** Un render target est lié à un modèle : toutes les télévisions du même modèle montrent la même image.
- **Le modèle doit avoir un render target.** Le réglage du builder est essayé en premier, puis `tvscreen`, `script_rt_ex_tvscreen`, `cinscreen`, `Big_Disp`, `ECG`. Si aucun ne convient, l'écran reste noir (activer `Debug` dans `config.lua`).
- **YouTube peut refuser la lecture intégrée** (message « lecteur refusé par YouTube », erreur 153) : YouTube veut un site d'origine pour l'intégration. Dans ce cas, héberger une copie de `html/player.html` sur un site https et mettre son adresse dans `PlayerUrl` (`config.lua`). Une vidéo dont l'auteur interdit l'intégration (erreurs 101 / 150) ne se lira jamais.
- Les réglages `scale` et `offset_*` du builder ne servent pas : ils concernent un autre mode de rendu (écran dessiné en 3D) qui n'est pas implémenté.
- Les vidéos s'arrêtent au redémarrage du serveur, et au bout de 6 h (`MaxPlaySeconds`).
