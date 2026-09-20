---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.DMVSchool = {
    maxErrorsCount = 3,
    speedLimit = 70,
    engineHealthLimit = 750,

    positionOutVehicle = vector4(213.63278198242, 388.45648193359, 105.85018920898, 173.29510498047),

    positionOutPlane = vector4(-1717.63, -2925.85, 12.94, 241.78),

    positionOutBoat = vector4(-797.55, -1503.36, -1.4, 123.99),

    goodAnswer = {
        ["question1.webp"] = 3,
        ["question2.webp"] = 2,
        ["question3.webp"] = 2,
        ["question4.webp"] = 3,
        ["question5.webp"] = 1,
        ["question6.webp"] = 4,
        ["question7.webp"] = 3,
        ["question8.webp"] = 1,
        ["question9.webp"] = 3,
        ["question10.webp"] = 2,
    },

    questions = {
        {
            name = "Dans cette situation :",
            picture = "question1.webp",
            answer = {
                { letter = "A", name = "Je peux avancer", selected = false },
                { letter = "B", name = "Je peux tourner", selected = false },
                { letter = "C", name = "Je dois m'arrêter", selected = false },
                { letter = "D", name = "Je dois accélérer", selected = false },
            },
        },
        {
            name = "Comment puis-je me garer ? :",
            picture = "question2.webp",
            answer = {
                { letter = "A", name = "En créneau", selected = false },
                { letter = "B", name = "En bataille", selected = false },
                { letter = "C", name = "En épis", selected = false },
                { letter = "D", name = "En arrière", selected = false },
            }
        },
        {
            name = "Dans cette situation, est-ce que je peux tourner à gauche :",
            picture = "question3.webp",
            answer = {
                { letter = "A", name = "Oui", selected = false },
                { letter = "B", name = "Non", selected = false },
                { letter = "C", name = "les 2", selected = false },
                { letter = "D", name = "Peut-être", selected = false },
            }
        },
        {
            name = "Un policier me braque mais le feu est vert, que dois-je faire ? :",
            picture = "question4.webp",
            answer = {
                { letter = "A", name = "J'attends que le piéton passe pour avancer", selected = false },
                { letter = "B", name = "J’écrase les deux individus", selected = false },
                { letter = "C", name = "J’écoute le policier donc je m’arrête", selected = false },
                { letter = "D", name = "J'active les essuie glace", selected = false },
            }
        },
        {
            name = "Quel est l’indice le plus important :",
            picture = "question5.webp",
            answer = {
                { letter = "A", name = "Le feu", selected = false },
                { letter = "B", name = "Le panneau", selected = false },
                { letter = "C", name = "Le groupe de filles a droite", selected = false },
                { letter = "D", name = "La voiture", selected = false }
            }
        },
        {
            name = "Je provoque un accident où je suis le seul en faute car je suis sous cocaïne, que dois-je faire :",
            picture = "question6.webp",
            answer = {
                { letter = "A", name = "Je repars comme si de rien n'était", selected = false },
                { letter = "B", name = "Je reprends un rail de cocaïne pour y voir plus clair", selected = false },
                { letter = "C", name = "Je contacte un mécano pour reprendre ma voiture", selected = false },
                -- Libellé selon la mentalité serveur (config/locale.lua) : FR = "secours", US = "EMS".
                { letter = "D", name = MENTA_SERVER == "FR" and "Je contacte les secours" or "Je contacte les EMS", selected = false }
            }
        },
        {
            name = "Suis-je bien garé ? :",
            picture = "question7.webp",
            answer = {
                { letter = "A", name = "Oui le poste de secours n'a rien à faire ici", selected = false },
                { letter = "B", name = "Non sur le sable c’est mieux", selected = false },
                { letter = "C", name = "Non", selected = false },
                { letter = "D", name = "Je dois accélérer", selected = false }
            }
        },
        {
            name = "Ça fait 24h que je roule sans arrêt, que dois-je faire :",
            picture = "question8.webp",
            answer = {
                { letter = "A", name = "Faire une petite pause de 2 heures", selected = false },
                { letter = "B", name = "Je mets les warning pour prévenir les autres conducteurs que je risque de m'évanouir",
                    selected = false },
                { letter = "C", name = "J’incline mon siège au maximum pour pouvoir conduire et me reposer en même temps",
                    selected = false },
                { letter = "D", name = "Je fais une vidéo 24h en voiture", selected = false },
            }
        },
        {
            name = "Un sanglier me bloque la route, quelle décision dois-je prendre :",
            picture = "question9.webp",
            answer = {
                { letter = "A", name = "J’en profite pour le dépecer et me faire de l’argent sur son dos",
                    selected = false },
                { letter = "B", name = "J’appelle mon assurance pour me sortir de cette histoire", selected = false },
                { letter = "C", name = "Je le contourne", selected = false },
                { letter = "D", name = "Je fait un barbecue avec le sanglier", selected = false },
            }
        },
        {
            name = "Qu'est-ce que je peux faire dans cette situation :",
            picture = "question10.webp",
            answer = {
                { letter = "A", name = "Prier", selected = false },
                { letter = "B", name = "Appeler les pompiers", selected = false },
                { letter = "C", name = "Appeler les taxis", selected = false },
                { letter = "D", name = "Faire une photo souvenir", selected = false },
            }
        },
    },

    positionDMVExamen = {
        vector3(240.66004943848, 344.50360107422, 103.92846679688), -- premiere pos
        vector3(208.40623474121, 220.91751098633, 103.99837493896), -- premiere pos
        vector3(342.67443847656, 133.38719177246, 101.41775512695), -- premiere pos
        vector3(284.38916015625, -58.001621246338, 68.533348083496), -- premiere pos
        vector3(209.41746520996, -53.703098297119, 67.340065002441), -- premiere pos
        vector3(154.2042388916, -171.11674499512, 52.700862884521), -- premiere pos
        vector3(0.7884179353714, -130.72621154785, 54.880508422852), -- premiere pos
        vector3(-228.22822570801, -45.624557495117, 47.924396514893), -- premiere po
        vector3(-294.31112670898, -155.58270263672, 39.580848693848), -- premiere pos
        vector3(-399.59902954102, -210.26139831543, 34.658554077148), -- premiere pos
        vector3(-550.61010742188, -283.61111450195, 33.557636260986), -- premiere pos
        vector3(-614.50006103516, -195.0376739502, 35.969482421875), -- premiere pos
        vector3(-683.23699951172, -211.79432678223, 35.573783874512), -- premiere pos
        vector3(-756.83868408203, -119.47229003906, 36.261486053467), -- premiere pos
        vector3(-826.47625732422, 3.6288502216339, 40.496070861816), -- premiere pos
        vector3(-856.30859375, 198.12733459473, 71.825065612793), -- premiere pos
        vector3(-918.20623779297, 268.93649291992, 68.653907775879), -- premiere pos
        vector3(-873.26049804688, 402.59848022461, 85.362182617188), -- premiere po
        vector3(-741.87261962891, 464.73031616211, 102.23853302002), -- premiere po
        vector3(-570.54077148438, 510.90393066406, 104.03946685791), -- premiere pos
        vector3(-500.15368652344, 567.68151855469, 118.11968231201), -- premiere pos
        vector3(-351.11813354492, 484.78790283203, 111.98870849609), -- premiere pos
        vector3(-145.72190856934, 514.17724609375, 138.96005249023), -- premiere pos
        vector3(256.48617553711, 535.89196777344, 138.85845947266), -- premiere pos
        vector3(238.01452636719, 447.00338745117, 119.90544128418), -- premiere pos
        vector3(413.58001708984, 357.34701538086, 106.31111907959), -- premiere pos
        vector3(276.66827392578, 337.46469116211, 103.9035949707), -- premiere pos
        vector3(231.57231140137, 385.33514404297, 104.84858703613), -- FIN RANGEMENT VOITURE
    },

    positionPlaneExamen = {
        vector3(-1274.49, -3386.87, 13.94),  -- Décollage aéroport LSIA
        vector3(-1623.02, -2792.15, 100.0),    -- Point de virage 1
        vector3(-1045.67, -2525.35, 200.0),   -- Point de virage 2
        vector3(-725.56, -1445.67, 150.0),      -- Approche montagne
        vector3(-1274.49, -3386.87, 13.94)    -- Atterrissage final
    },

    positionBoatExamen = {
        vector3(-3426.71, 967.99, 8.35),      -- Départ du port
        vector3(-2987.56, 458.23, 2.15),      -- Virage autour de l'île
        vector3(-3320.12, 371.45, 0.15),      -- Passage étroit
        vector3(-3490.33, 1024.56, 1.1),      -- Retour vers le port
        vector3(-3426.71, 967.99, 8.35)       -- Arrivée finale
    },

    positionHeliExamen = {
        vector3(-745.14, -1468.67, 5.0),      -- Décollage hélipad
        vector3(-860.45, -1345.67, 120.0),      -- Point haut 1
        vector3(-600.78, -930.45, 150.0),      -- Déplacement latéral
        vector3(-300.23, -1230.56, 100.0),    -- Approche zone urbaine
        vector3(-745.14, -1468.67, 5.0)        -- Atterrissage final
    },
}
