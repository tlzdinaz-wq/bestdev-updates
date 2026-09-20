# Habillages CSS du bundle (`interface/build/skin/`)

Feuilles chargées par `interface/build/index.html` **après** le CSS compilé du
bundle React : elles re-stylisent des écrans livrés sans sources.

| Fichier | Écran |
|---|---|
| `boss-panel.css` | Tablette patron (`.container-boss-panel` et ses modales) |
| `notifications.css` | Toasts HUD, aide, annonces |
| `status-hud.css` | HUD statut : barres vie / armure (capsule, icônes, segments) et jauges faim / soif / oxygène (anneaux, pastille %) — thèmes du bundle conservés |

Ces fichiers sont livrés minifiés. Les versions lisibles et les sources des pages
(boutique, pause menu, hub de gestion, annonces, HUD, menus VUI…) ne font pas
partie de la base distribuée.
