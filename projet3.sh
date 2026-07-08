#!/bin/bash
#script bash du jeu

#Encore besoin de .conf qui contient les valeurs des pors sns
source ./Outil.sh	# port et ip, barre de chargem et notif, nc, audio, tmux
source ./score.sh	#contient les fichier de progressions, et score etc;;;
source ./Menu.sh
source ./assist.sh
source ./duel.sh
source ./quotidien.sh
SERVEUR_DUEL="./serveur1"
CLIENT_DUEL="./client1"
PORT_DUEL=9000

# =================================================================
# AUTO-PROJECTION DANS TMUX POUR LE MODE CLI
# =================================================================
if [ -z "$DISPLAY" ]; then
    # Si on n'est pas déjà dans une session tmux
    if [ -z "$TMUX" ]; then
        check_tmux # Vérifie/installe tmux via Outil.sh
        
        # Lance une nouvelle session tmux nommée 'MasterLin' et y exécute ce même script
        tmux new-session -s "MasterLin" -A "$0"
        exit 0 # Quitte l'instance hors-tmux actuelle
    fi
fi

nettoyage_interruption() {
    arreter_ecoute "$PORT1" 2>/dev/null
    arreter_ecoute "$PORT2" 2>/dev/null
    if [ -n "$TMUX" ]; then
        tmux kill-session -t "MasterLin" 2>/dev/null
    fi
    exit 1
}

# Capture le signal de fermeture (SIGINT = Ctrl+C, SIGTERM = arrêt propre)
trap nettoyage_interruption SIGINT SIGTERM

#==============================================================
#			Styles et couleurs
#==============================================================
RESET="\033[0m"
BOLD="\033[1m"
UNDERLINE="\033[4m"

#--------------------------------------------------------------
CYAN="\033[36m"
MAGENTA="\033[35m"
GREEN="\033[32m"
YELLOW="\033[33m"
PURPLE='\033[38;5;135m'
CORAL='\033[38;5;209m'
GRAY='\033[38;5;245m'
WHITE='\033[38;5;255m'
#--------------------------------------------------------------

# Tonalités du Thème Quiz / Gaming
QUIZ_BLUE="\033[38;5;27m"     
CYAN_LIGHT="\033[96m"        
GOLD_AMBER="\033[38;5;214m"   
WHITE_BRIGHT="\033[97m"

# Alertes et Confirmations
RED_BRIGHT="\033[91m"       
GREEN_BRIGHT="\033[92m"

# Styles des Bandeaux pleins
BANNER_QUIZ="\033[1;48;5;214;30m"

#================================================================

# Couleurs locales avancées
FRAME_COLOR="\033[38;5;220m"       # Or/Jaune Industriel pour le cadre
INNER_CYAN="\033[1;38;5;51m"       # Cyan néon pour les flèches et numéros
TECH_BLUE="\033[1;38;5;27m"        # Bleu pour les chevrons de saisie
OPTION_TITLE="\033[1;97m"          # Blanc Gras Éclatant pour les titres d'options
OPTION_DESC="\033[38;5;246m"       # Gris adouci pour les descriptions d'options
BADGE_ALERT="\033[1;38;5;196m"     # Rouge écarlate pour l'option Quitter
    
#=================================================================

#on autorise la récéption des messages dès le lancement du script
mesg y 2>/dev/null

ip_pc2=""
prenom=""
Theme_actuel=""
numero_theme=""
minimum=60
export fichier_joueur="/tmp/Joueurs"
touch "$fichier_joueur"
export PORT1=6855
export PORT2=5586
export PORT3=7000

export TMUX_PANE_CIBLE="$TMUX_PANE"
pid_msg1=$(demarrer_ecoute "$PORT1")

accueil() {
    clear
    #----------------Logo---------------------
    echo -e "${CYAN_LIGHT}${BOLD}"
    echo "  __  __    _    ____ _____ _____ ____  _     ___ _   _ " ; sleep 0.20
    echo " |  \/  |  / \  / ___|_   _| ____|  _ \| |   |_ _| \ | |" ; sleep 0.20
    echo " | |\/| | / _ \ \___ \ | | |  _| | |_) | |    | ||  \| |" ; sleep 0.20
    echo " | |  | |/ ___ \ ___) || | | |___|  _ <| |___ | || |\  |" ; sleep 0.20
    echo " |_|  |_/_/   \_\____/ |_| |_____|_| \_\_____|___|_| \_|" ; sleep 0.20
    echo -e "${RESET}"

     # --- CADRE DE PLATEAU DE JEU ---
    echo -e "${QUIZ_BLUE}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}      Q U I Z Z   E T   A P P R E N T I S S A G E   L I N U X     ${RESET} ${QUIZ_BLUE}║${RESET}"
    echo -e "${QUIZ_BLUE}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    echo -e "${WHITE_BRIGHT}${BOLD}${UNDERLINE}Les joueurs existants:${RESET}"
    echo -e "${BOLD} ${QUIZ_BLUE}"
   
   # 1. Lire, trier par ordre alphabétique et stocker dans un tableau Bash
    declare -A liste_joueurs
    local compteur=1

    if [ -s /var/log/masterlin/players.txt ]; then
        while IFS= read -r nom_trie; do
            [ -z "$nom_trie" ] && continue
            liste_joueurs[$compteur]="$nom_trie"
            echo -e "   [${compteur}] ==> $nom_trie"
            compteur=$((compteur + 1))
        done < <(sort -f /var/log/masterlin/players.txt)
    else
        echo -e "   (Aucun joueur enregistré pour le moment)"
    fi
    echo -e "${RESET}"

    echo -e "${BOLD}${WHITE_BRIGHT}Entrez le NUMÉRO de votre joueur ou écrivez un NOUVEAU NOM, ou 'suppr' pour supprimer un joueur :${RESET}"
    read -r saisie
    echo ""

    if [ "$saisie" = "suppr" ]; then
    	supprimer_joueur
    	accueil
    	return
    fi
    
     if [[ "$saisie" =~ ^[0-9]+$ ]] && [ -n "${liste_joueurs[$saisie]}" ]; then
        prenom="${liste_joueurs[$saisie]}"
        echo -e "${GREEN_BRIGHT}Joueur sélectionné : ${BOLD}$prenom${RESET}"
    else
        # 4. Traitement s'il s'agit d'un nouveau nom de joueur
        prenom="$saisie"
 
        if grep -qx "$prenom" /var/log/masterlin/players.txt; then
            echo -e "${GREEN_BRIGHT}Joueur '${BOLD}$prenom${RESET}${GREEN_BRIGHT}' reconnu. Bienvenue !${RESET}"
            echo ""
        else
            echo "$prenom" >> /var/log/masterlin/players.txt
            echo ""
            echo -e "      ${GOLD_AMBER}===================================================${RESET}"
            echo -e "         ${BOLD}${WHITE_BRIGHT}HELLO ${CYAN_LIGHT}$prenom${WHITE_BRIGHT} ! ARE YOU READY ?${RESET}"
            echo -e "      ${GOLD_AMBER}===================================================${RESET}"
            echo ""
        fi
    fi

    init_progression
    barre_chargement
    sleep 1
}

supprimer_joueur() {
    echo ""
    echo -e "      ${RED_BRIGHT}╔══════════════════════════════════════╗${RESET}"
    echo -e "      ${RED_BRIGHT}║${RESET}    ${BOLD}${WHITE_BRIGHT}SUPPRESSION D'UN JOUEUR${RESET}           ${RED_BRIGHT}║${RESET}"
    echo -e "      ${RED_BRIGHT}╚══════════════════════════════════════╝${RESET}"
 
    if [ ! -s /var/log/masterlin/players.txt ]; then
        echo -e "      ${RED_BRIGHT}Aucun joueur à supprimer.${RESET}"
        sleep 2
        return
    fi
 
    declare -A liste_suppr
    local compteur=1
    while IFS= read -r nom_trie; do
        [ -z "$nom_trie" ] && continue
        liste_suppr[$compteur]="$nom_trie"
        echo -e "   [${compteur}] ==> $nom_trie"
        compteur=$((compteur + 1))
    done < <(sort -f MasterLin/players.txt)
 
    echo -e -n "${BOLD}${WHITE_BRIGHT}Numéro du joueur à supprimer (ou 'annuler') : ${RESET}"
    read -r num_suppr
    echo ""
 
    if [ "$num_suppr" = "annuler" ]; then
        echo -e "      ${GOLD_AMBER}Suppression annulée.${RESET}"
        sleep 1
        return
    fi
 
    if [[ "$num_suppr" =~ ^[0-9]+$ ]] && [ -n "${liste_suppr[$num_suppr]}" ]; then
        local nom_cible="${liste_suppr[$num_suppr]}"
        echo -e -n "${RED_BRIGHT}Confirmer la suppression de ${BOLD}$nom_cible${RESET}${RED_BRIGHT} ? (o/n) : ${RESET}"
        read -r confirmation
        if [ "$confirmation" = "o" ] || [ "$confirmation" = "O" ]; then
            sed -i "/^${nom_cible}$/d" /var/log/masterlin/players.txt
            rm -rf /var/log/masterlin/progression_${nom_cible}.txt 2>/dev/null
            echo -e "      ${GREEN_BRIGHT}Joueur '${BOLD}$nom_cible${RESET}${GREEN_BRIGHT}' supprimé.${RESET}"
        else
            echo -e "      ${GOLD_AMBER}Suppression annulée.${RESET}"
        fi
    else
        echo -e "      ${RED_BRIGHT}Numéro invalide.${RESET}"
    fi
    sleep 2
}

menu_principal()
{
    while true; do
        clear
        echo -e "\a" 
        notif "Entrer le numéro correspondant à votre choix"
        
        C_HAUT=$FRAME_COLOR; C_BAS="\033[38;5;39m"
        C_MILIEU=$FRAME_COLOR
        C_HAUT="\033[38;5;39m"; C_BAS=$FRAME_COLOR
        C_MILIEU="\033[38;5;39m"

        # --- BLOC TABLEAU DE BORD GRAND FORMAT CORRIGÉ (72 CARACTÈRES DE LARGEUR AXE) ---
        echo -e "${C_HAUT}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${C_MILIEU}║${RESET}   ${BOLD}${WHITE_BRIGHT}        		  - MENU PRINCIPAL -                           ${RESET}${C_MILIEU}║${RESET}"
        echo -e "${C_HAUT}╠══════════════════════════════════════════════════════════════════════╢${RESET}"
        echo -e "${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}   ${INNER_CYAN}[1]${RESET} ──► ${OPTION_TITLE}JOUER${RESET}      ${OPTION_DESC}- Lancer le Quiz interactif du Systeme          ${RESET}${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}   ${INNER_CYAN}[2]${RESET} ──► ${OPTION_TITLE}A PROPOS${RESET}   ${OPTION_DESC}- Details et modules du projet MasterLin        ${RESET}${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}   ${INNER_CYAN}[3]${RESET} ──► ${OPTION_TITLE}HISTORIQUE${RESET} ${OPTION_DESC}- Consulter le Registre Central des Scores      ${RESET}${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}   ${BADGE_ALERT}[4]${RESET} ──► ${BADGE_ALERT}QUITTER${RESET}    ${OPTION_DESC}- Interrompre et fermer l'application           ${RESET}${C_MILIEU}║${RESET}"
        echo -e "${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
        echo -e "${C_HAUT}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
         echo -e -n "${INNER_CYAN}ENTRER VOTRE CHOIX (1-4) :${RESET}"
     	read choix
     	
        while [ -z "$choix" ]; do
            echo -e -n "${INNER_CYAN}Redéfinissez votre choix (1-4) :${RESET} "
            read choix
        done

        while [ "$choix" != '1' -a "$choix" != '2' -a "$choix" != '3' -a "$choix" != '4' ]; do
            echo -e -n "${INNER_CYAN}Redéfinissez votre choix (1-4) :${RESET} "
            read choix
        done

        if [ "$choix" = '1' ]; then
            clear
            Mode
    
        elif [ "$choix" = '2' ]; then
        echo -e "${QUIZ_BLUE}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}                     A   P R O P O S                                ${RESET} ${QUIZ_BLUE}║${RESET}"
            echo -e "${QUIZ_BLUE}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            echo -e "      ${GOLD_AMBER}===================================================${RESET}"
            echo -e "        MasterLin - Jeu de quiz Linux"
            echo -e "        4 modules : fichiers, texte, permissions, processus"
            echo -e "        3 niveaux de difficulté par module"
            echo -e "        Mode assistance pour les quiz guidés et Mode duel pour un 1v1"
            echo -e "      ${GOLD_AMBER}===================================================${RESET}"
            echo ""
            echo -e "      Appuyez sur [Entree] pour revenir au menu..."
            read

        elif [ "$choix" = '3' ]; then
            clear
           # En-tête principal parfaitement calibré (74 caractères de large)
            echo -e "  ${QUIZ_BLUE}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "  ${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}            H I S T O R I Q U E   D E S   S C O R E S               ${RESET} ${QUIZ_BLUE}║${RESET}"
            echo -e "  ${QUIZ_BLUE}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            
            echo -e "  ${C_HAUT}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}   ${BOLD}${WHITE_BRIGHT}SÉLECTIONNEZ LE REGISTRE DE PROGRESSION SOUHAITÉ${RESET}                   ${C_MILIEU}║${RESET}"
            echo -e "  ${C_HAUT}╠══════════════════════════════════════════════════════════════════════╣${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}   ${INNER_CYAN}[1]${RESET} ──► ${BOLD}${WHITE_BRIGHT}HISTORIQUE SOLO${RESET}  ${OPTION_DESC}- Consulter vos scores locaux             ${RESET}${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}   ${INNER_CYAN}[2]${RESET} ──► ${BOLD}${WHITE_BRIGHT}HISTORIQUE DUEL${RESET}  ${OPTION_DESC}- Voir les résultats des duels réseau     ${RESET}${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}   ${INNER_CYAN}[3]${RESET} ──► ${BOLD}${WHITE_BRIGHT}RETOUR PANEL${RESET}     ${OPTION_DESC}- Revenir au panneau principal            ${RESET}${C_MILIEU}║${RESET}"
            echo -e "  ${C_MILIEU}║${RESET}                                                                      ${C_MILIEU}║${RESET}"
            echo -e "  ${C_HAUT}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            echo -e -n "      ${INNER_CYAN}FAITES VOTRE CHOIX (1-3) :${RESET} "
            read histo
            echo ""
            
            while [ -z "$histo" ]; do
                echo -e "      ${RED_BRIGHT}Choix vide. Redefinissez votre choix : ${RESET}"
                read histo
            done
            
            while [ "$histo" != '1' -a "$histo" != '2' -a "$histo" != '3' ]; do
                echo -e "      ${RED_BRIGHT}Choix invalide. Redefinissez votre choix (1-3) : ${RESET}"
                read histo
            done
            
            if [ "$histo" = '1' ]; then
                if [ -f /var/log/masterlin/historique.txt ]; then
                    echo -e "      ${CYAN_LIGHT}--- SCORES SOLO ---${RESET}"
                    cat /var/log/masterlin/historique.txt
                else
                    echo -e "      ${RED_BRIGHT}Pas de scores pour le moment.${RESET}"
                fi
                echo ""
                echo -e "${BOLD}${GRAY}      Appuyez sur Entree pour revenir...${RESET}"
                read
            elif [ "$histo" = '2' ]; then
                if [ -f /var/log/masterlin//historique_duel.txt ]; then
                    echo -e "      ${CYAN_LIGHT}--- SCORES DUEL ---${RESET}"
                    cat /var/log/masterlin/historique_duel.txt
                else
                    echo -e "      ${RED_BRIGHT}Pas de duel pour le moment.${RESET}"
                fi
                echo ""
                echo -e "${BOLD}${GRAY}      Appuyez sur Entree pour revenir...${RESET}"
                read
            elif [ "$histo" = '3' ]; then
                # Option 3 : Quitte proprement ce sous-menu pour retourner au menu principal
                echo -e "      ${GOLD_AMBER}Retour au panneau de contrôle principal...${RESET}"
                sleep 1
            else
                echo -e "      ${RED_BRIGHT}Choix invalide.${RESET}"
                sleep 15
            fi
            	
        elif [ "$choix" = '4' ]; then
        	echo " "
        	echo -e "      ${BOLD}${GOLD_AMBER}Au revoir!${RESET}"
            	sleep 3
            	clear
            	if [ -n "$TMUX" ]; then
                  # On tue la session courante proprement
                  tmux kill-session -t "MasterLin"
                fi
                arreter_ecoute "$PORT1"
                arreter_ecoute "$PORT2"
		exit 0
        fi
    done
}

quizz()
{
    clear
    notif "Bonne chance !"
    local niveau=$1
    local fichier_question=""
    local score=0
    local total=5
    local numeroquest=1

    if [ "$niveau" = "niveau1" ]; then
        fichier_question="questions/facile${numero_theme}.csv"
    elif [ "$niveau" = "niveau2" ]; then
        fichier_question="questions/moyen${numero_theme}.csv"
    elif [ "$niveau" = "niveau3" ]; then
        fichier_question="questions/difficile${numero_theme}.csv"
    fi

    if [ ! -f "$fichier_question" ]; then
        echo "Fichier questions introuvable : $fichier_question"
        sleep 3
        return
    fi
    
    echo ""
    echo -e " ${CORAL}	    ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""
    echo -e "	${BOLD}${CORAL} 	   		Q U I Z ${RESET}"
    echo ""
    echo -e " ${CORAL}	   ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""
    sleep 1
    clear
    echo ""
    echo -e "${QUIZ_BLUE}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}      Thème: $Theme_actuel                                  ${RESET} ${QUIZ_BLUE}║${RESET}"
    echo -e "${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}      Niveau: $niveau                                             ${RESET} ${QUIZ_BLUE}║${RESET}"
    echo -e "${QUIZ_BLUE}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    sleep 0.5

    # variable 'ligne' remplacée par les vraies variables lues
    while IFS='|' read -r question C1 C2 C3 C4 bonne; do

        # Ignorer lignes vides ou commentaires (filtre de sécurité)
        [ -z "$question" ] && continue
        [[ "$question" == \#* ]] && continue
        
	echo ""
        echo -e "${CORAL}	        === Question $numeroquest/$total ===	${RESET}"
        echo -e "${CORAL}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    	echo -e "${CORAL}║${RESET}                    Score: $score                                       ${RESET} ${CORAL}║${RESET}"
    	echo -e "${CORAL}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${BOLD}=================================================================================${RESET}"
        echo " $question"
        echo ""
        echo "  [1] $C1"
        echo "  [2] $C2"
        echo "  [3] $C3"
        echo "  [4] $C4"
        echo ""
        echo -e "${BOLD}=================================================================================${RESET}"
        echo ""
        echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' pour quitter ❯ ${RESET} "
        read reponse < /dev/tty

        while [ "$reponse" != '1' -a "$reponse" != '2' -a "$reponse" != '3' -a "$reponse" != '4' -a "$reponse" != 'q' ]; do
            echo "Option invalide"
            sleep 1
            echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' ❯${RESET} "
            read reponse < /dev/tty
        done
        
        if [ "$reponse" = "q" ]; then
        	echo ""
        	echo -e "${BOLD}${GRAY}...Vous abandonnez la partie...${RESET}"
        	sleep 1
        	return 0
        fi

        if [ "$reponse" = "$bonne" ]; then
            echo ""
            echo -e "${BOLD}${GREEN} Bonne réponse ! +1 point${RESET}"
            notif "Bien joué !"
            score=$((score + 1))
            sleep 2
            clear
        else
            local texte_bonne=""
            if [ "$bonne" = "1" ]; then texte_bonne="$C1"
            elif [ "$bonne" = "2" ]; then texte_bonne="$C2"
            elif [ "$bonne" = "3" ]; then texte_bonne="$C3"
            elif [ "$bonne" = "4" ]; then texte_bonne="$C4"
            fi
            echo ""
            echo -e "${BOLD}${RED_BRIGHT} Mauvaise réponse.${RESET}"
            echo -e "${YELLOW}La bonne réponse était :${RESET} ${BOLD}${WHITE_BRIGHT} $texte_bonne${RESET}"
            notif "Pas de chance !"
            sleep 2
            clear
        fi

        numeroquest=$((numeroquest + 1))
        sleep 3

    # pipeline propre — grep filtre, shuf mélange, head limite à $total
    done < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n $total)

    resultat "$score" "$total" "$niveau"
    
}

echo "$(date '+%d/%m/%Y %H:%M') Lancement de MasterLin par $USER" >> /var/log/masterlin/masterlin.connexion
accueil

envoie_annonce &
pid_envoie_annonce=$!
ecoute_annonce &
pid_annonce=$!

menu_principal


