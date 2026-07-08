# MasterLin

Jeu de quiz interactif en terminal pour apprendre l'administration système Linux, packagé sous forme de paquet Debian (`.deb`).

Projet réalisé dans le cadre du Semestre 1 — L1 Mention Informatique Technologie, Université d'Antananarivo.

**Auteurs :** Gracia, Kanto, Sambatra, Sarobidy

---

## Sommaire

- [Présentation](#présentation)
- [Modes de jeu](#modes-de-jeu)
- [Thèmes couverts](#thèmes-couverts)
- [Installation](#installation)
- [Dépendances](#dépendances)
- [Utilisation](#utilisation)
- [Structure du projet](#structure-du-projet)
- [Fichiers de logs](#fichiers-de-logs)
- [Limites connues](#limites-connues)
- [Désinstallation](#désinstallation)

---

## Présentation

MasterLin permet d'apprendre l'administration système à travers un outil interactif en Bash, avec :

- Un mode **Solo** pour s'entraîner seul, à son rythme.
- Un mode **Assistant** utilisant le réseau Wi-Fi local pour obtenir un support en temps réel d'un autre joueur.
- Un mode **Duel** synchronisé en temps réel entre deux joueurs, avec un vrai serveur réseau écrit en C.
- Un **Défi du jour** qui ne pose pas de question à choix multiple : il exécute une commande réelle sur le système et vérifie automatiquement si l'état obtenu correspond à ce qui était attendu.

## Modes de jeu

| Mode | Description |
|---|---|
| Solo | Entraînement individuel, progression et score sauvegardés par joueur |
| Assistant | Support en temps réel via le réseau local (`nc`), affichage via `zenity` |
| Duel | Deux joueurs s'affrontent en réseau sur la même question, en temps réel (serveur C, sockets, `select()`) |
| Défi du jour | Trois défis pratiques exécutés et vérifiés sur le véritable système |

## Thèmes couverts

Chaque thème se décline en trois niveaux de difficulté, débloqués progressivement à partir de 60 % de réussite au niveau précédent :

1. Gestion de fichiers
2. Traitement de texte
3. Droits et permissions
4. Gestion des processus

## Installation

```bash
sudo dpkg -i masterlin-pkg.deb
sudo apt-get install -f   # si des dépendances manquent
```

Le script `postinst` du paquet configure automatiquement les permissions d'exécution, initialise `/var/log/masterlin/`, et met en place la rotation hebdomadaire des logs via `cron.d`.

## Dépendances

- `bash` (>= 4.0)
- `gcc` — compilation du serveur/client du mode Duel
- `libc6`
- `iproute2`
- `netcat`
- `tmux`
- `psmisc`

## Utilisation

Une fois installé, lancer simplement :

```bash
masterlin
```

Le menu principal propose ensuite le choix du mode de jeu, puis du thème et du niveau de difficulté.

## Structure du projet

```
masterlin-pkg/
├── DEBIAN/
│   ├── control        # métadonnées du paquet
│   ├── postinst        # script post-installation
│   └── postrm           # script post-désinstallation
├── usr/
│   ├── games/
│   │   └── masterlin     # point d'entrée
│   └── share/
│       ├── projet3.sh     # orchestrateur principal
│       ├── Menu.sh         # navigation, sélection thèmes/niveaux, quiz solo
│       ├── score.sh          # persistance de la progression
│       ├── duel.sh             # orchestration du mode duel
│       ├── assist.sh            # mode assistant réseau
│       ├── Outil.sh               # configuration, utilitaires réseau
│       ├── quotidien.sh            # défi du jour
│       ├── serveur1.c                # serveur réseau du mode duel
│       ├── client1.c                  # client réseau du mode duel
│       └── questions/                  # banques de questions (CSV)
└── var/log/                             # logs runtime
```

## Fichiers de logs

Créés dans `/var/log/masterlin/` à l'installation :

- `historique.txt` — historique des parties solo
- `historique_duel.txt` — historique des duels
- `players.txt` — joueurs détectés en mode assistant/duel
- `defi.log` — journal des défis du jour
- `suivis_defis.txt` — suivi des défis réussis par jour et par utilisateur

Les logs de solo/duel sont pivotés automatiquement (7 derniers jours conservés) via une tâche cron installée par le paquet.

## Limites connues

Ce projet a été conçu pour un usage pédagogique en salle de TP ou sur poste personnel, pas pour un déploiement multi-utilisateurs en production. En particulier :

- Le mode Duel n'implémente pas d'authentification réseau : toute machine sur le même réseau local peut se connecter au serveur pendant la fenêtre d'attente.
- Le mode Assistant suppose une interface Wi-Fi nommée selon la convention `wl*` et un environnement graphique disponible pour `zenity`.
- Les permissions des logs partagés sont volontairement larges pour permettre l'écriture multi-joueurs ; elles mériteraient un groupe dédié dans un contexte multi-utilisateurs non contrôlé.

## Désinstallation

```bash
sudo dpkg -r masterlin
```
## Pour récupérer le .deb

Veuillez contacter un de nous 4 😉
