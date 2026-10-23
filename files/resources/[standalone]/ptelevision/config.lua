PTVConfig = {
    -- Distance (m) a laquelle un ecran affiche l'image. Au-dela, plus de DUI : rien n'est charge.
    VisualRange = 60.0,

    -- Distance maximale (m) entre un joueur et la television pour lancer / arreter une video,
    -- et pour ouvrir le controleur (lecture, pause, avance).
    PlayRange = 25.0,
    ControlRange = 25.0,

    -- Nombre d'ecrans allumes en meme temps sur le serveur.
    MaxScreens = 40,

    -- Une video lancee est arretee d'office au bout de ce delai (secondes).
    MaxPlaySeconds = 6 * 3600,

    -- Delai minimal (ms) entre deux lancements par un meme joueur.
    PlayCooldownMs = 2000,

    -- Page de lecture. Par defaut celle de la ressource (nui://ptelevision/html/player.html). Si YouTube
    -- refuse la lecture integree (erreur 153 « lecteur refuse »), heberger une copie de html/player.html
    -- sur un site https et mettre son adresse ici : YouTube exige un site d'origine, pas un nui://.
    PlayerUrl = nil,

    -- Liens directs vers un fichier video (.mp4, .webm, .ogv, .m4v, .mov) en plus de YouTube.
    -- Chaque joueur proche de l'ecran contacte l'hote du lien : mettre false pour n'accepter que YouTube.
    AllowDirectLinks = true,

    -- Reglages d'un modele absent de la liste du builder (Gestion > Builder > Television).
    DefaultModel = {
        target = 'tvscreen',
        scale = 0.085,
        offset_x = -1.02,
        offset_y = -0.055,
        offset_z = 1.04,
        range = 20.0,
        default_volume = 0.5,
        dui_width = 1280,
        dui_height = 720,
    },

    -- Modeles utilises tant que core n'a pas fourni la liste du builder.
    SeedModels = {
        'prop_tv_flat_01', 'prop_tv_flat_01b', 'prop_tv_flat_02', 'prop_tv_flat_03',
        'prop_tv_03', 'prop_tv_06', 'prop_tv_07', 'v_res_tre_tv', 'v_res_mtv',
    },

    -- Intervalle (ms) auquel un client redemande l'etat des ecrans de son instance.
    SyncIntervalMs = 5000,

    -- Journal dans la console (F8 cote client, console serveur).
    Debug = false,
}
