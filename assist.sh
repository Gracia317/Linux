#!/bin/bash
source ./Outil.sh
assist () {
if [ -n "$pid_msg1" ]; then
        kill "$pid_msg1" 2>/dev/null
        wait "$pid_msg1" 2>/dev/null
    fi
recevoir_msg "$PORT2" &
pid_msg2=$!

clear
    echo ""
    echo -e " ${CORAL}	    ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""	
    echo -e "   ${CORAL}╔═════════════════════════════════════════════════════════╗${RESET}"
    echo -e "   ${CORAL}║${RESET}               ${BG_CYN}${BLD}MODE ASSISTANT ACTIVÉ  ${RESET}                   ${CORAL}║${RESET}"
    echo -e "   ${CORAL}╠═════════════════════════════════════════════════════════╣${RESET}"
    echo -e "   ${CORAL}║${RESET}     ${V_YLW}  Alerte : Connexion via WLAN requise ${RESET}              ${CORAL}║${RST}"
    echo -e "   ${CORAL}╚═════════════════════════════════════════════════════════╝${RESET}"

    echo ""
    echo -e " ${CORAL}	   ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""
    echo -e " ${BOLD}      		⚠️ Connexion via WLAN requis ⚠️ ${RESET} "
    echo ""

# Trouver l'interface Wi-Fi active
wifi_interface=$(ls /sys/class/net | grep -E '^wl')

if [ -z "$wifi_interface" ]; then
    echo -e "${RED_BRIGHT}Pas de carte Wi-Fi détectée.${RESET}"
    exit 1
fi
# Vérifier si le Wi-Fi est connecté (operstate = up)
if [ "$(cat /sys/class/net/$wifi_interface/operstate)" = "up" ]; then
    echo -e "        ${BOLD}${CYAN}Connecté à un réseau sans fil (WLAN) via${RESET} $wifi_interface"
   check_nc
   check_audio
   echo "               Recherche des joueurs sur le réseau..."
   sleep 4    # laisser le temps au premier cycle d'envoie_annonce de finir
   nettoyer_joueurs_inactifs
   if [ ! -s "$fichier_joueur" ]; then
    echo -e "${BOLD}${RED_BRIGHT}Aucun joueur détecté.${RESET}"
    echo -e "${GRAY}Appuyez sur Entrée pour relancer la recherche ou 'q' pour quitter${RESET}"
    read rep < /dev/tty
    if [ "$rep" = "q" ];then
    return
    else
    assist   # relancer
    return
    fi
    fi
   
   echo -e "${UNDERLINE}${BOLD}Joueurs disponibles :${RESET}"
   echo -e "${BOLD}---------------------${RESET}"
   awk -F ':' '{printf "[%s]  %s\n", $2, $3}' "$fichier_joueur"
   echo -e "${BOLD}---------------------${RESET}"
   echo ""
   echo -e "${BOLD}Lequel de ces joueurs voulez vous choisir comme assistant? ${UNDERLINE}ou${RESET} ${BOLD}Appuyer sur [ENTREE] pour quitter${RESET}"
   read -p "Entrez son IP : " ip_pc2
   if [ -z $ip_pc2 ]; then
   	return 0
   else
   	ping -c 1 -w 1 "$ip_pc2" > /dev/null 2>&1 
   	if [ $? -ne 0 ]; then
           echo -e "${RED_BRIGHT}Non connecté${RESET}"
           sleep 2
           return 1
        else
           sleep 2
           modules_as
        fi
    fi
else
    echo "vous êtes non connecté, veuillez vous connecter"
fi
}

quizz_as ()
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

    clear	
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
    
    #  IFS='|' sans espace — lecture correcte des champs
    # variable 'ligne' remplacée par les vraies variables lues
    while IFS='|' read -r question C1 C2 C3 C4 bonne; do
        # Ignorer lignes vides ou commentaires (filtre de sécurité)
        [ -z "$question" ] && continue
        [[ "$question" == \#* ]] && continue

        clear
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
        echo -e "${BOLD}Votre réponse? (1-4) ${UNDERLINE}ou${RESET} ${BOLD}'q'${RESET} pour quitter " 
        echo -e -n "${UNDERLINE}sinon${RESET}${BOLD} tapez 0 pour envoyer un message à l'assistant${RESET} ❯ "
        local choice
        local reponse

        while true; do
            read -r choice < /dev/tty
            [ -z "$choice" ] && return
            case "$choice" in
                0)
                    # ✅ FIX : forcer ecrire_msg à lire depuis /dev/tty
                    # pour éviter qu'elle lise le flux CSV de la boucle while
                    ecrire_msg "$ip_pc2" "$PORT1" </dev/tty
                    # Réafficher la question pour que le joueur puisse répondre
                    clear
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
        	echo -e "${BOLD}Votre réponse? (1-4) ${UNDERLINE}ou${RESET} ${BOLD}'q'${RESET} pour quitter " 
        	echo -e "${UNDERLINE}ou${RESET}${BOLD} tapez 0 pour envoyer un message à l'assistant${RESET}${UNDERLINE} ❯ "
                    ;;
                [1-4])
                    reponse="$choice"
                    if [ "$reponse" = "$bonne" ]; then
                        echo ""
                        echo -e "${BOLD}${GREEN}Bonne réponse ! +1 point${RESET}"
                        notif "Bien joué !"
                        score=$((score + 1))
                    else
                        local texte_bonne=""
                        if   [ "$bonne" = "1" ]; then texte_bonne="$C1"
                        elif [ "$bonne" = "2" ]; then texte_bonne="$C2"
                        elif [ "$bonne" = "3" ]; then texte_bonne="$C3"
                        elif [ "$bonne" = "4" ]; then texte_bonne="$C4"
                        fi
                        echo ""
                        echo -e "${BOLD}${RED_BRIGHT}Mauvaise réponse.${RESET}"
                        echo -e "${YELLOW}La bonne réponse était :${RESET}${BOLD} $texte_bonne ${RESET}"
                        notif "Pas de chance !"
                    fi
                    break  # On passe à la question suivante seulement ici
                    ;;
                    
                q|Q|"") 
                    # si la réponse est vide, c-à-d le joueur a appuyé sur entrée, on quitte
                    if [ -z "$reponse" ]; then 
                        echo ""
                        echo -e "${BOLD}${GRAY}Abandon du quiz... Retour au menu principal...${RESET}"
                        sleep 2
                        return # On stoppe la fonction et on retourne au menu principal
                    fi	
                    ;;
                *)
                    echo -e "${BOLD}${RED_BRIGHT}Option invalide. ${RESET} ${BOLD}Votre réponse? (1-4) ou 'q' pour quitter${RESET} "
                    echo -e "${UNDERLINE}ou${RESET}${BOLD} tapez 0 pour envoyer un message à l'assistant${RESET}${UNDERLINE} sinon${RESET}${BOLD} appuyer sur ENTREE pour quitter ❯  ${RESET}"
                    ;;
            esac
        done
        numeroquest=$((numeroquest + 1))
        sleep 3

    # pipeline propre — grep filtre, shuf mélange, head limite à $total
   done < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n $total)

    resultat "$score" "$total" "$niveau"
}
