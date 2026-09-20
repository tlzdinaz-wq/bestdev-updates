---@meta _
---@diagnostic disable: duplicate-doc-field

-- Questions for the code exam
Config.DVM.CodeQuestions = {
    -- General questions (common to all licenses)
    general = {
        {
            id = 1,
            question = "À quelle distance minimale devez-vous vous arrêter derrière un véhicule à un feu rouge ?",
            answers = {
                "Juste assez pour voir sa plaque d'immatriculation de près",
                "3 mètres",
                "La distance ne compte pas, l'essentiel est de klaxonner",
                "Un kilomètre pour être vraiment sûr"
            },
            correct = 2,
            explanation = "Il faut laisser au moins 3 mètres pour pouvoir manœuvrer en cas de problème."
        },
        {
            id = 2,
            question = "Que signifie un feu orange ?",
            answers = {
                "C'est le signal pour accélérer comme un pilote de course",
                "Arrêtez-vous si c'est possible en sécurité",
                "C'est l'heure de vérifier votre téléphone",
                "Faites un dérapage contrôlé pour impressionner"
            },
            correct = 2,
            explanation = "Le feu orange indique qu'il faut s'arrêter si on peut le faire en sécurité."
        },
        {
            id = 3,
            question = "En ville, quelle est la limitation de vitesse par défaut ?",
            answers = {
                "Aussi vite que votre voiture le permet",
                "100 km/h comme dans les films d'action",
                "50 km/h",
                "La vitesse recommandée par votre application GPS"
            },
            correct = 3,
            explanation = "En agglomération, la vitesse est limitée à 50 km/h sauf indication contraire."
        },
        {
            id = 4,
            question = "Quand devez-vous utiliser vos clignotants ?",
            answers = {
                "Jamais, c'est pour les amateurs",
                "Pour changer de voie et tourner",
                "Uniquement le dimanche",
                "Seulement quand la police vous regarde"
            },
            correct = 2,
            explanation = "Les clignotants doivent être utilisés pour indiquer tout changement de direction."
        },
        {
            id = 5,
            question = "Que devez-vous faire à un stop ?",
            answers = {
                "Ralentir un peu et continuer si personne ne regarde",
                "S'arrêter complètement",
                "C'est juste une suggestion, pas une obligation",
                "Faire un burnout pour tester vos pneus"
            },
            correct = 2,
            explanation = "Au panneau STOP, l'arrêt complet est obligatoire."
        },
        {
            id = 6,
            question = "À quelle distance devez-vous suivre le véhicule qui vous précède ?",
            answers = {
                "Le plus près possible pour économiser du carburant",
                "Juste assez pour voir son autocollant de pare-chocs",
                "3 secondes",
                "Pas besoin de distance si vous avez de bons réflexes"
            },
            correct = 3,
            explanation = "La règle des 3 secondes permet de garder une distance de sécurité suffisante."
        },
        {
            id = 7,
            question = "Que signifie un panneau triangulaire rouge et blanc ?",
            answers = {
                "C'est une décoration urbaine moderne",
                "C'est un panneau publicitaire défraîchi",
                "Danger",
                "Vous êtes dans un jeu vidéo"
            },
            correct = 3,
            explanation = "Les panneaux triangulaires rouges et blancs signalent un danger."
        },
        {
            id = 8,
            question = "Quand pouvez-vous utiliser votre téléphone en conduisant ?",
            answers = {
                "Quand le message est vraiment important",
                "Pendant que vous doublez, c'est plus sûr",
                "Tant que vous gardez un œil sur la route",
                "À l'arrêt moteur coupé"
            },
            correct = 4,
            explanation = "Le téléphone ne peut être utilisé qu'à l'arrêt, moteur coupé."
        },
        {
            id = 9,
            question = "Que devez-vous faire en cas d'accident ?",
            answers = {
                "Prendre un selfie pour les réseaux sociaux",
                "Sécuriser, alerter, secourir",
                "Négocier avec l'autre conducteur comme dans les films",
                "Chercher des témoins pour prouver que c'est pas votre faute"
            },
            correct = 2,
            explanation = "La conduite à tenir est : sécuriser, alerter, secourir."
        },
        {
            id = 10,
            question = "Quelle est la durée de validité d'un permis de conduire ?",
            answers = {
                "Jusqu'à ce que vous ayez un accident",
                "Tant que vous vous souvenez du code de la route",
                "15 ans",
                "Éternel, comme votre jeunesse"
            },
            correct = 3,
            explanation = "Le permis de conduire est valable 15 ans et doit être renouvelé."
        }
    },

    -- Specific questions for cars
    car = {
        {
            id = 101,
            question = "Avant de démarrer votre véhicule, que devez-vous vérifier ?",
            answers = {
                "Si votre playlist Spotify est prête",
                "Rétroviseurs, siège, ceinture",
                "Que votre café est bien dans le porte-gobelet",
                "Si vous avez assez de followers sur les réseaux sociaux"
            },
            correct = 2,
            explanation = "Il faut ajuster le siège, les rétroviseurs et attacher sa ceinture."
        },
        {
            id = 102,
            question = "Comment effectuer un créneau ?",
            answers = {
                "En fermant les yeux et en espérant le meilleur",
                "En klaxonnant jusqu'à ce que quelqu'un vous aide",
                "En plusieurs manœuvres avec marche arrière",
                "En faisant semblant de chercher une autre place"
            },
            correct = 3,
            explanation = "Le créneau nécessite plusieurs manœuvres incluant la marche arrière."
        },
        {
            id = 103,
            question = "Que signifie le voyant d'huile qui s'allume ?",
            answers = {
                "C'est l'heure de commander de la pizza",
                "Problème de pression d'huile",
                "Votre voiture a besoin d'affection",
                "C'est juste une décoration du tableau de bord"
            },
            correct = 2,
            explanation = "Le voyant d'huile indique un problème de pression d'huile moteur."
        },
        {
            id = 104,
            question = "En cas de pluie, vous devez :",
            answers = {
                "Prétendre que vous êtes dans Fast & Furious",
                "Augmenter les distances de sécurité",
                "Laver votre voiture gratuitement",
                "Conduire les yeux fermés, c'est plus excitant"
            },
            correct = 2,
            explanation = "Par temps de pluie, il faut augmenter les distances de sécurité."
        },
        {
            id = 105,
            question = "Quand devez-vous allumer vos feux de croisement ?",
            answers = {
                "Quand vous voulez impressionner les autres conducteurs",
                "Dès que la visibilité est réduite",
                "Jamais, ça consomme trop de batterie",
                "Uniquement pour les photos Instagram"
            },
            correct = 2,
            explanation = "Les feux de croisement doivent être allumés dès que la visibilité est insuffisante."
        }
    },

    -- Specific questions for motorcycles
    motorcycle = {
        {
            id = 201,
            question = "Quel équipement est obligatoire pour conduire une moto ?",
            answers = {
                "Un t-shirt 'Born to be Wild' et des lunettes de soleil",
                "Une cape de super-héros pour voler",
                "Juste votre courage et votre sens du style",
                "Équipement complet homologué"
            },
            correct = 4,
            explanation = "Un équipement de protection complet et homologué est obligatoire."
        },
        {
            id = 202,
            question = "Comment négocier un virage en moto ?",
            answers = {
                "En fermant les yeux et en priant",
                "En faisant un wheeling pour impressionner",
                "En ralentissant avant et en penchant",
                "En accélérant à fond comme dans les jeux vidéo"
            },
            correct = 3,
            explanation = "Il faut ralentir avant le virage et pencher la moto pour le négocier."
        },
        {
            id = 203,
            question = "Quelle est la particularité du freinage en moto ?",
            answers = {
                "Freiner avec vos pieds à la Flintstones",
                "Crier 'STOP!' très fort",
                "Utiliser les deux freins simultanément",
                "Laisser le vent vous arrêter naturellement"
            },
            correct = 3,
            explanation = "Il faut utiliser les deux freins de manière coordonnée."
        },
        {
            id = 204,
            question = "Par vent fort, vous devez :",
            answers = {
                "Ouvrir un parapluie pour aller plus vite",
                "Faire comme si vous étiez un cerf-volant",
                "Réduire la vitesse et être vigilant",
                "Décoller comme dans E.T."
            },
            correct = 3,
            explanation = "Par vent fort, il faut réduire la vitesse et redoubler de vigilance."
        },
        {
            id = 205,
            question = "Comment vous rendre visible en moto ?",
            answers = {
                "Porter un costume de clown multicolore",
                "Porter des équipements réfléchissants",
                "Attacher des ballons à votre casque",
                "Conduire avec les feux de détresse en permanence"
            },
            correct = 2,
            explanation = "Les équipements réfléchissants améliorent la visibilité du motard."
        }
    },

    -- Specific questions for trucks
    truck = {
        {
            id = 301,
            question = "Quelle est la limitation de vitesse pour un poids lourd en ville ?",
            answers = {
                "Aussi vite que vous pouvez avant que votre café se renverse",
                "La vitesse nécessaire pour livrer à temps",
                "50 km/h",
                "Ça dépend de combien vous êtes pressé"
            },
            correct = 3,
            explanation = "En ville, les poids lourds sont limités à 50 km/h comme les autres véhicules."
        },
        {
            id = 302,
            question = "Qu'est-ce que l'angle mort d'un poids lourd ?",
            answers = {
                "L'endroit où vous cachez vos snacks",
                "Une zone non visible dans les rétroviseurs",
                "La zone où vous ne voyez pas vos regrets",
                "Un coin secret pour faire une sieste"
            },
            correct = 2,
            explanation = "L'angle mort est une zone non visible dans les rétroviseurs du conducteur."
        },
        {
            id = 303,
            question = "Comment effectuer un virage avec un poids lourd ?",
            answers = {
                "En fermant les yeux et en tournant le volant",
                "En prenant large et en surveillant l'arrière",
                "Comme dans un jeu de bowling géant",
                "En espérant que les autres s'écartent"
            },
            correct = 2,
            explanation = "Il faut prendre large et surveiller que l'arrière du véhicule ne heurte rien."
        },
        {
            id = 304,
            question = "Quelle est la distance de freinage d'un poids lourd ?",
            answers = {
                "Juste appuyer sur le frein et c'est bon",
                "Comme une voiture, c'est pareil",
                "Beaucoup plus longue",
                "Négligeable si vous avez de la chance"
            },
            correct = 3,
            explanation = "La distance de freinage d'un poids lourd est beaucoup plus longue."
        },
        {
            id = 305,
            question = "Que devez-vous vérifier avant de prendre la route ?",
            answers = {
                "Si votre station de radio préférée passe bien",
                "L'arrimage de la cargaison",
                "Que votre camion est bien plus gros que les autres",
                "Le nombre de followers sur votre blog de camionneur"
            },
            correct = 2,
            explanation = "L'arrimage de la cargaison est essentiel pour la sécurité."
        }
    }
}

---@description Shuffle a table
---@param tbl table
---@return table
local function shuffleTable(tbl)
    local shuffled = {}
    for i = 1, #tbl do
        shuffled[i] = tbl[i]
    end

    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    return shuffled
end

---@description Shuffle answers and update correct answer index
---@param question table
---@return table
local function shuffleAnswers(question)
    -- Create a deep copy to avoid modifying the original
    local shuffled = {
        id = question.id,
        question = question.question,
        answers = {},
        correct = question.correct,
        explanation = question.explanation
    }

    -- Copy answers
    for i = 1, #question.answers do
        shuffled.answers[i] = question.answers[i]
    end

    -- Store the correct answer text
    local correctAnswerText = shuffled.answers[shuffled.correct]

    -- Shuffle the answers
    shuffled.answers = shuffleTable(shuffled.answers)

    -- Find the new index of the correct answer
    for i = 1, #shuffled.answers do
        if shuffled.answers[i] == correctAnswerText then
            shuffled.correct = i
            break
        end
    end

    return shuffled
end

---@description Generate a random exam
---@param licenseType string
---@param numQuestions number
---@return table
function Config.DVM.GenerateExam(licenseType, numQuestions)
    local questions = {}
    local generalQuestions = Config.DVM.CodeQuestions.general
    local specificQuestions = Config.DVM.CodeQuestions[licenseType] or {}

    -- Shuffle the general questions
    local shuffledGeneral = shuffleTable(generalQuestions)

    -- Shuffle the specific questions
    local shuffledSpecific = shuffleTable(specificQuestions)

    -- Take 70% of general questions and 30% specific questions
    local numGeneral = math.floor(numQuestions * 0.7)
    local numSpecific = numQuestions - numGeneral

    -- Add the general questions
    for i = 1, math.min(numGeneral, #shuffledGeneral) do
        table.insert(questions, shuffledGeneral[i])
    end

    -- Add the specific questions
    for i = 1, math.min(numSpecific, #shuffledSpecific) do
        table.insert(questions, shuffledSpecific[i])
    end

    -- Shuffle answers for each question
    for i = 1, #questions do
        questions[i] = shuffleAnswers(questions[i])
    end

    -- Shuffle the final question order
    questions = shuffleTable(questions)

    return questions
end