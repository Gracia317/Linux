#!/bin/bash
#script bash du jeu

source ./score.sh	#contient les fichier de progressions, et score etc;;;
source ./Outil.sh	# port et ip, barre de chargem et notif, notif, checknmap, installation nmap, nc
source ./Menu.sh
source ./assist.sh
source ./duel.sh
SERVEUR_DUEL="./serveur1"
CLIENT_DUEL="./client1"
PORT_DUEL=9000

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
GREEN_BRIGHT="\033[92m"QUIZ_BLUE

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
export PORT1=6855
export PORT2=5586

recevoir_msg "$PORT1" &
pid_msg1=$!

connexion_joueur() {
    local prenom=$1
    echo -e "      ${QUIZ_BLUE}╔══════════════════════════════════════╗${RESET}"
    echo -e "      ${QUIZ_BLUE}║${RESET}    ${BOLD}${WHITE_BRIGHT}JOUEUR EXISTANT !${RESET}                 ${QUIZ_BLUE}║${RESET}"  
    echo -e "      ${QUIZ_BLUE}╚══════════════════════════════════════╝${RESET}"
    echo -e -n "      ${BOLD}${WHITE_BRIGHT}Entrez votre mot de passe (secret) : ${RESET}"
    read -s mot_de_passe    
    echo ""
    
    local saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    local stocke=$(grep "^$prenom:" MasterLin/password.txt | cut -d ':' -f2)
   
    local tentative=0
    while [ "$saisi" != "$stocke" ]; do
        tentative=$(( tentative + 1 ))
        if [ "$tentative" -eq 5 ]; then
            echo -e "${RED_BRIGHT}Mot de passe oublié après 5 tentatives?${RESET}"
            echo -e "${GREEN_BRIGHT}Veuillez saisir un tout nouveau mot de passe:${RESET}"
            read -s mot_de_passe
            echo ""
            nouveau=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
            
            sed -i "s/^$prenom:.*/$prenom:$nouveau/" MasterLin/password.txt
            
            echo -e "${BOLD}${WHITE_BRIGHT}Mot de passe changé avec succès !${RESET}"
            break
        fi
            echo ""
            echo -e "      ${RED_BRIGHT}Mot de passe incorrect !${RESET}"
            echo -e "      ${RED_BRIGHT}╔══════════════════════════════════════╗${RESET}"
            echo -e "      ${RED_BRIGHT}║${RESET}    ${BOLD}${WHITE_BRIGHT}SECURITE - VERIFICATION${RESET}           ${RED_BRIGHT}║${RESET}"
            echo -e "      ${RED_BRIGHT}╚══════════════════════════════════════╝${RESET}"
            echo -e -n "      ${BOLD}${WHITE_BRIGHT}Veuillez reessayer : ${RESET}"
            read -s mot_de_passe
            echo ""
        saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    done
    
	echo ""
        echo -e "      ${GOLD_AMBER}===================================================${RESET}"
        echo -e "         ${BOLD}${WHITE_BRIGHT}REBONJOUR ${CYAN_LIGHT}$prenom${WHITE_BRIGHT} ! DE RETOUR DANS LE JEU ?${RESET}"
        echo -e "      ${GOLD_AMBER}===================================================${RESET}"
        echo ""
}

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

    if [ ! -d MasterLin ]; then
        mkdir MasterLin
        touch MasterLin/password.txt
        chmod 600 MasterLin/password.txt
    fi

    echo -e "${WHITE_BRIGHT}${BOLD}${UNDERLINE}Les joueurs existants:${RESET}"
    echo -e "${BOLD} ${QUIZ_BLUE}"
    awk -F ':' '{printf "==>%s\n",$1}' MasterLin/password.txt
    echo ""
    echo -e "${RESET}"

    echo -e "${BOLD}${WHITE_BRIGHT}Entrer votre nom de joueur ou créez-en un nouveau:"${RESET}
    read prenom
    echo ""

    # Si le joueur existe
    if grep -q "^$prenom:" MasterLin/password.txt ; then
        connexion_joueur "$prenom"
    else
    	echo ""
        echo -e "${RED_BRIGHT}Ce nom ne correspond à aucun joueur existant. Créer un nouveau joueur?${RESET}"
        echo -e "[o] oui    [n] non    [autre] pour quitter"
        read noui
        case $noui in
            o|O)
            	echo ""
            	echo -e "      ${CYAN_LIGHT}╔══════════════════════════════════════╗${RESET}"
        	echo -e "      ${CYAN_LIGHT}║${RESET}    ${BOLD}${WHITE_BRIGHT}NOUVEAU JOUEUR DETECTE !${RESET}         ${CYAN_LIGHT} ║${RESET}"
        	echo -e "      ${CYAN_LIGHT}╚══════════════════════════════════════╝${RESET}"
                echo -e -n "${BOLD}${WHITE_BRIGHT} Entrez votre mot de passe: ${RESET}"
                read -s mot_de_passe
                echo ""
                pwd_hash=$(echo -n "$mot_de_passe" | sha256sum | cut -d ' ' -f1)
                echo "$prenom:$pwd_hash" >> MasterLin/password.txt
                echo ""
        	echo -e "      ${GOLD_AMBER}===================================================${RESET}"
        	echo -e "         ${BOLD}${WHITE_BRIGHT}HELLO ${CYAN_LIGHT}$prenom${WHITE_BRIGHT} ! ARE YOU READY ?${RESET}"
        	echo -e "      ${GOLD_AMBER}===================================================${RESET}"
        	echo ""
                ;;
                
            n|N)
            	echo ""
                echo -e "${RED_BRIGHT}Veuillez entrer un nom de joueur existant...${RESET}"
                read prenom
                if grep -q "^$prenom:" MasterLin/password.txt ; then
                    connexion_joueur "$prenom"
                else
                    echo -e "${BOLD}${RED_BRIGHT}Joueur introuvable. Fin du programme.${RESET}"
                    exit 1
                fi
                ;;
                
            *)
                echo -e "${BOLD}${RED_BRIGHT}Choix invalide.${RESET}"
                exit 1
                ;;
        esac
    fi

    init_progression
    barre_chargement
    sleep 1
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
            echo -e "      Appuyez sur Entree pour revenir au menu..."
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
                if [ -f MasterLin/historique.txt ]; then
                    echo -e "      ${CYAN_LIGHT}--- SCORES SOLO ---${RESET}"
                    cat MasterLin/historique.txt
                else
                    echo -e "      ${RED_BRIGHT}Pas de scores pour le moment.${RESET}"
                fi
                echo ""
                echo "      Appuyez sur Entree pour revenir..."
                read
            elif [ "$histo" = '2' ]; then
                if [ -f MasterLin/historique_duel.txt ]; then
                    echo -e "      ${CYAN_LIGHT}--- SCORES DUEL ---${RESET}"
                    cat MasterLin/historique_duel.txt
                else
                    echo -e "      ${RED_BRIGHT}Pas de duel pour le moment.${RESET}"
                fi
                echo ""
                echo "      Appuyez sur Entree pour revenir..."
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
            	sleep 4
            	clear
            	exit 0
        fi
    done
    
   if [ -n "$pid_msg1" ]; then
        kill "$pid_msg1" 2>/dev/null
        wait "$pid_msg1" 2>/dev/null
    fi
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

accueil
menu_principal

