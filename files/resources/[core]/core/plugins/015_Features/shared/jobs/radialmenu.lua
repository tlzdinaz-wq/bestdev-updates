---@meta _
---@diagnostic disable: duplicate-doc-field

VFW.Jobs.RadialMenu = {
    lspd = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "OpenSubRadialJobs",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty",
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "VEHICULE",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenSubRadialJobs",
                args = "vehicule"
            },
        },
        vehicule = {
            {
                name = "RECHERCHE PLAQUE",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "VehiclePlateSearchAction"
            },
            {
                name = "RADAR",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "ToggleRadarAction"
            },
            {
                name = "FOURRIERE",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "VehicleImpoundAction"
            },
            {
                name = "POSER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleBootAction"
            },
            {
                name = "RETIRER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleUnbootAction"
            },
            {
                name = "DEVERROUILLER",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "VehicleUnlockAction"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        },
        papiers = {
            {
                name = "CONVOCATION",
                icon = VFW.CDN.Get("radialmenus/top_paper.svg"),
                action = ""
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "DEPOSITION",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = ""
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
    },
    lssd = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "OpenSubRadialJobs",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty",
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "VEHICULE",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenSubRadialJobs",
                args = "vehicule"
            },
        },
        vehicule = {
            {
                name = "RECHERCHE PLAQUE",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "VehiclePlateSearchAction"
            },
            {
                name = "RADAR",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "ToggleRadarAction"
            },
            {
                name = "FOURRIERE",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "VehicleImpoundAction"
            },
            {
                name = "POSER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleBootAction"
            },
            {
                name = "RETIRER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleUnbootAction"
            },
            {
                name = "DEVERROUILLER",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "VehicleUnlockAction"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        },
        papiers = {
            {
                name = "CONVOCATION",
                icon = VFW.CDN.Get("radialmenus/top_paper.svg"),
                action = ""
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "DEPOSITION",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = ""
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
    },
    sams = {
        main = {
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/bpm.svg"),
                action = "OpenSubRadialJobs",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/player.svg"),
                action = "OpenSubRadialJobs",
                args = "objets"
            }
        },
        papiers = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "CERTIFICAT",
                icon = VFW.CDN.Get("radialmenus/health_paper.svg"),
                action = ""
            }
        },
        objets = {
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRANCARD",
                icon = VFW.CDN.Get("radialmenus/health_tool.svg"),
                action = "ToggleBrancard"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
    },
    usss = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        papiers = {
            {
                name = "CONVOCATION",
                icon = VFW.CDN.Get("radialmenus/top_paper.svg"),
                action = ""
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "DEPOSITION",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = ""
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "VEHICULE",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenSubRadialJobs",
                args = "vehicule"
            },
        },
        vehicule = {
            {
                name = "RECHERCHE PLAQUE",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "VehiclePlateSearchAction"
            },
            {
                name = "RADAR",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "ToggleRadarAction"
            },
            {
                name = "FOURRIERE",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "VehicleImpoundAction"
            },
            {
                name = "POSER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleBootAction"
            },
            {
                name = "RETIRER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleUnbootAction"
            },
            {
                name = "DEVERROUILLER",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "VehicleUnlockAction"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        },
    },
    lsfd = {
        main = {
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/bpm.svg"),
                action = "OpenSubRadialJobs",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/fire_extinguisher.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        papiers = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "CERTIFICAT",
                icon = VFW.CDN.Get("radialmenus/health_paper.svg"),
                action = ""
            }
        },
        actions = {
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "OpenSubRadialJobs",
                args = "objets"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "INCENDIE",
                icon = VFW.CDN.Get("radialmenus/fire_station.svg"),
                action = "ToggleHose"
            },
        },
        objets = {
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRANCARD",
                icon = VFW.CDN.Get("radialmenus/health_tool.svg"),
                action = "ToggleBrancard"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        incendie = {
            {
                name = "LANCE",
                icon = VFW.CDN.Get("radialmenus/fire_extinguisher.svg"),
                action = "ToggleHose"
            },
            {
                name = "MOUSSE",
                icon = VFW.CDN.Get("radialmenus/repair.svg"),
                action = "ToggleFoam"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        }
    },
    gouv = {
        main = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice",
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "CONTRAT",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "",
            }
        },
    },
    doj = {
        main = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice",
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "CONTRAT",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "",
            }
        },
    },
    sasp = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "OpenSubRadialJobs",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty",
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "VEHICULE",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenSubRadialJobs",
                args = "vehicule"
            },
        },
        vehicule = {
            {
                name = "RECHERCHE PLAQUE",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "VehiclePlateSearchAction"
            },
            {
                name = "RADAR",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "ToggleRadarAction"
            },
            {
                name = "FOURRIERE",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "VehicleImpoundAction"
            },
            {
                name = "POSER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleBootAction"
            },
            {
                name = "RETIRER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleUnbootAction"
            },
            {
                name = "DEVERROUILLER",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "VehicleUnlockAction"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        },
        papiers = {
            {
                name = "CONVOCATION",
                icon = VFW.CDN.Get("radialmenus/top_paper.svg"),
                action = ""
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "DEPOSITION",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = ""
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
    },
    cayomilice = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty",
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
        },
    },
    usmc = {
        main = {
            {
                name = "APPEL DE RENFORT",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "OpenSubRadialJobs",
                args = "renfort"
            },
            {
                name = "PAPIERS",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "",
                args = "papiers"
            },
            {
                name = "PRISE DE SERVICE",
                icon = VFW.CDN.Get("radialmenus/checkmark.svg"),
                action = "SetJobDuty"
            },
            {
                name = "ACTIONS",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            }
        },
        renfort = {
            {
                name = "PANIC BUTTON",
                icon = VFW.CDN.Get("radialmenus/police_logo.svg"),
                action = "MakePanicCall",
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            }
        },
        papiers = {
            {
                name = "CONVOCATION",
                icon = VFW.CDN.Get("radialmenus/top_paper.svg"),
                action = ""
            },
            {
                name = "FACTURE",
                icon = VFW.CDN.Get("radialmenus/billet.svg"),
                action = "OpenInvoice"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "DEPOSITION",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = ""
            }
        },
        actions = {
            {
                name = "ANNONCE",
                icon = VFW.CDN.Get("radialmenus/megaphone.svg"),
                action = "CreateJobAdvert"
            },
            {
                name = "CIRCULATION",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenCerculationenu"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "main"
            },
            {
                name = "OBJETS",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "MenuJobsObjet"
            },
            {
                name = "BRACELET",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "ToggleBracelet"
            },
            {
                name = "VEHICULE",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "OpenSubRadialJobs",
                args = "vehicule"
            },
        },
        vehicule = {
            {
                name = "RECHERCHE PLAQUE",
                icon = VFW.CDN.Get("radialmenus/paper.svg"),
                action = "VehiclePlateSearchAction"
            },
            {
                name = "RADAR",
                icon = VFW.CDN.Get("radialmenus/road.svg"),
                action = "ToggleRadarAction"
            },
            {
                name = "FOURRIERE",
                icon = VFW.CDN.Get("radialmenus/police.svg"),
                action = "VehicleImpoundAction"
            },
            {
                name = "POSER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleBootAction"
            },
            {
                name = "RETIRER SABOT",
                icon = VFW.CDN.Get("radialmenus/object.svg"),
                action = "VehicleUnbootAction"
            },
            {
                name = "DEVERROUILLER",
                icon = VFW.CDN.Get("interacts/point.svg"),
                action = "VehicleUnlockAction"
            },
            {
                name = "RETOUR",
                icon = VFW.CDN.Get("radialmenus/leave.svg"),
                action = "OpenSubRadialJobs",
                args = "actions"
            },
        },
    },
}
