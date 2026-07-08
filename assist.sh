#!/bin/bash
source ./Outil.sh
assist () {
# demarrer_ecoute libère systématiquement le port avant de le réutiliser
# (fuser, pas juste kill sur le PID) : ça reste sans danger même si assist()
# se rappelle elle-même (aucun joueur trouvé) et qu'un ancien pid_msg2
# tournait déjà dessus - avant, ce cas précis créait un conflit de port.
arreter_ecoute "$PORT1"
export TMUX_PANE_CIBLE="$TMUX_PANE"
pid_msg2=$(demarrer_ecoute "$PORT2")

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
    return 1
fi
# Vérifier si le Wi-Fi est connecté (operstate = up)
if [ "$(cat /sys/class/net/$wifi_interface/operstate)" = "up" ]; then
    echo -e "        ${CYAN}Connecté à un réseau sans fil (WLAN) via ${RESET} $wifi_interface"
   check_nc
   check_audio
   echo "              Recherche des joueurs sur le réseau..."
   echo ""
   sleep 4    # laisser le temps au premier cycle d'envoie_annonce de finir
   nettoyer_joueurs_inactifs
   if [ ! -s "$fichier_joueur" ]; then
    echo -e "${YELLOW}Aucun joueur détecté.${RESET}"
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
   echo ""
   
   if [ -z "$ip_pc2" ]; then
   	pid_msg1=$(demarrer_ecoute "$PORT1")
   	return 0
   else
   	# Le ping seul est peu fiable en WiFi : beaucoup de box/hotspots activent
   	# l'isolation client qui bloque l'ICMP entre appareils du même réseau,
   	# même quand les ports nc seraient parfaitement joignables. On retente
   	# le ping avec un délai plus réaliste, puis on vérifie directement le
   	# port en pur bash (/dev/tcp) si le ping échoue, avant de conclure.
   	if ping -c 2 -W 2 "$ip_pc2" > /dev/null 2>&1 || timeout 2 bash -c "echo >/dev/tcp/${ip_pc2}/${PORT3}" 2>/dev/null; then
           sleep 2
           modules_as
        else
           echo -e "${RED_BRIGHT}Non connecté${RESET}"
           sleep 2
           pid_msg1=$(demarrer_ecoute "$PORT1")
           return 1
        fi
    fi
   
else
    echo -e "${BOLD}${RED_BRIGHT}vous êtes non connecté, veuillez vous connecter${RESET}"
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
         echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' pour quitter ❯ ${RESET} " 
        echo -e "${UNDERLINE}ou${RESET} ${BOLD}tapez 0 pour envoyer un message à l'assistant${RESET}"
        echo -e "${UNDERLINE}...sinon${RESET} ${BOLD}tapez sur [ENTREE] pour quitter...${RESET}"
        local choice
        local reponse

        while true; do
            read -r choice < /dev/tty
            [ -z "$choice" ] && return
            case "$choice" in
                0)
                    #  FIX : forcer ecrire_msg à lire depuis /dev/tty
                    # pour éviter qu'elle lise le flux CSV de la boucle while
                    ecrire_msg "$ip_pc2" "$PORT1" </dev/tty
                    # Réafficher la question pour que le joueur puisse répondre
                    echo ""
                    echo "=== Question $numeroquest/$total ==="
                    echo " $question"
                    echo "  [1] $C1"
                    echo "  [2] $C2"
                    echo "  [3] $C3"
                    echo "  [4] $C4"
                    echo ""
                    echo "Votre réponse (1-4) ou 0 pour envoyer un message sinon [ENTREE] pour quitter:"
                    
                    ;;
                [1-4])
                    reponse="$choice"
                    if [ "$reponse" = "$bonne" ]; then
                        echo ""
                        echo "Bonne réponse ! +1 point"
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
                        echo "Mauvaise réponse."
                        echo "La bonne réponse était : $texte_bonne"
                        notif "Pas de chance !"
                    fi
                    break  # On passe à la question suivante seulement ici
                    ;;
                    
                "") 
                    echo "Abandon du quiz... Retour au menu principal."
                    sleep 2
                    return # On stoppe la fonction et on retourne au menu principal	
                    ;;
                *)
                    echo "Option invalide. Entrez 1-4 pour répondre ; 0 pour envoyer un message; ou [ENTREE] pour quitter"
                    ;;
            esac
        done
        numeroquest=$((numeroquest + 1))
        sleep 3

    # pipeline propre — grep filtre, shuf mélange, head limite à $total
   done < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n $total)

    resultat "$score" "$total" "$niveau"
    
    arreter_ecoute "$PORT2"
    export TMUX_PANE_CIBLE="$TMUX_PANE"
    pid_msg1=$(demarrer_ecoute "$PORT1")
}
