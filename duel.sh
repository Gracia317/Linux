#!/bin/bash
 
affiche_duel()
{
    clear
    echo ""
    echo -e " ${CORAL}	    ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""
    echo -e "	${BOLD}${CORAL} 	        M O D E    D U E l ${RESET}"
    echo ""
    echo -e " ${CORAL}	   ◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo ""
    echo ""
    echo -e "${CORAL}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CORAL}║${RESET}    ${BOLD}${WHITE_BRIGHT}[1]${RESET} Lancer un round duel    (Joueur A / Serveur)               ${RESET} ${CORAL}║${RESET}"
    echo -e "${CORAL}║${RESET}    ${BOLD}${WHITE_BRIGHT}[2]${RESET} Rejoindre un round duel (Joueur B / Client)                ${RESET} ${CORAL}║${RESET}"
    echo -e "${CORAL}║${RESET}    ${BOLD}${WHITE_BRIGHT}[3]${RESET} Retour au menu principal                                   ${RESET} ${CORAL}║${RESET}"
    echo -e "${CORAL}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e -n "      ${INNER_CYAN}FAITES VOTRE CHOIX (1-3) :${RESET} "
    read safidy
    echo ""
 
    case "$safidy" in
        1)
            IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1)
            [ -z "$IP_LOCAL" ] && IP_LOCAL=$(hostname -I | awk '{print $1}')
            
            echo ""
            echo -e "      ${QUIZ_BLUE}╔════════════════════════════════════════════════════════════╗${RESET}"
    	    echo -e "          ${BOLD}${WHITE_BRIGHT}TON IP RÉSEAU ACTIVE :${RESET} $IP_LOCAL   "                    
    	    echo -e "          ${BOLD}${WHITE_BRIGHT}Port de Duel         :${RESET} $PORT_DUEL   "                          
            echo -e "      ${QUIZ_BLUE}╚════════════════════════════════════════════════════════════╝${RESET}"
            echo ""
            echo "        [*] Donne cette IP exacte au Joueur B."
            echo ""
            quiz_duel_serveur
            ;;
        2)
            local ip_serveur=""
            echo -e "${BOLD}Entrez l'IP du serveur (Joueur A) (Vous devez être sur le même réseau): "
            echo -e "ou tapez sur ENTREE pour quitter...${RESET}"
            read ip_serveur
            if [ -z "$ip_serveur" ]; then
                echo -e "${RED_BRIGHT}IP vide. Annulation.${RESET}"
                sleep 1
                return
            fi
            quiz_duel_client "$ip_serveur"
            ;;
        3)
            return 0
            ;;
        *)
            echo -e "${BOLD}${RED_BRIGHT }Choix invalide.${RESET}"
            sleep 1
            ;;
    esac
}
 
compiler_duel()
{
    if [ ! -f "./serveur1" ] || [ ! -f "./client1" ]; then
        echo "[*] Compilation des modules C..."
        gcc -o serveur1 serveur1.c 2>/dev/null
        gcc -o client1 client1.c 2>/dev/null
        if [ ! -f "./serveur1" ] || [ ! -f "./client1" ]; then
            echo "ERREUR : La compilation a échoué. Vérifiez vos fichiers C."
            read -rp "Appuyez sur ENTREE..." </dev/tty
            return 1
        fi
        echo "Compilation réussie !"
    fi
    return 0
}

# CORRECTION CRITIQUE : Nettoyage global sans wait bloquant
nettoyage_duel()
{
    # On rase tous les processus éphémères résiduels pour libérer le port instantanément
    killall -9 serveur1 client1 2>/dev/null
    
    # Suppression propre des descripteurs de fichiers temporaires de cette session
    rm -f /tmp/duel_qstA_*_$$ /tmp/duel_repA_*_$$
    rm -f /tmp/duel_qstB_*_$$ /tmp/duel_repB_*_$$
    rm -f /tmp/duel_srv_$$.log
}
 
# ================================================================
# JOUEUR A — SERVEUR
# ================================================================
quiz_duel_serveur()
{
    compiler_duel || return 1
    nettoyage_duel # Nettoyage préventif
 
    local fichier_question="questions/questionsduel.csv"
    [ ! -f "$fichier_question" ] && fichier_question="questionsduel.csv"
    if [ ! -f "$fichier_question" ]; then
        echo -e "${RED_BRIGHT}Fichier questionsduel.csv introuvable !${RESET}"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    mapfile -t QUESTIONS < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n 10) #mapfile est comme un tableau portant le nom QUESTIONS qui stocke les 10 lignes aléatoires
 
    local total=${#QUESTIONS[@]} #total = au nombre case du tableau QUESTIONS généré par mapfile
    if [ "$total" -eq 0 ]; then
        echo -e "${RED_BRIGHT}Aucune question trouvée dans le fichier CSV.${RESET}"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    local numeroquest=1
    local score_A=0
    local score_B=0
 
    echo ""
    echo ""
    echo -e "${BOLD}[*] En attente du Joueur B..."
    echo ""
    read -rp "Appuyez sur ENTREE pour ouvrir la session de jeu... " </dev/tty
    echo -e "${RESET}"
    mkdir -p duel
 
    while [ $numeroquest -le $total ]; do
        local idx=$((numeroquest - 1))
        local ligne="${QUESTIONS[$idx]}"
        IFS='|' read -r question C1 C2 C3 C4 bonne <<< "$ligne"
 
        # Sécurité entre chaque question : On s'assure que le port 9000 est VRAIMENT libre
        killall -9 serveur1 client1 2>/dev/null
        sleep 0.4 
 
        # Lancement du serveur pour la question en cours
        "$SERVEUR_DUEL" "$PORT_DUEL" "$bonne" "$ligne" > /tmp/duel_srv_$$.log 2>&1 &
 
        # Attente active du signal SERVEUR_PRET généré par serveur1.c
        local attente=0
        while [ $attente -lt 30 ]; do
            grep -q "SERVEUR_PRET" /tmp/duel_srv_$$.log 2>/dev/null && break
            sleep 0.2; attente=$((attente + 1))
        done
        
        if [ $attente -ge 30 ]; then
            echo "Port $PORT_DUEL engorgé. Réinitialisation du socket..."
            nettoyage_duel
            sleep 1; continue
        fi
 
        local tmp_qst="/tmp/duel_qstA_${numeroquest}_$$"
        local tmp_rep="/tmp/duel_repA_${numeroquest}_$$"
        rm -f "$tmp_qst" "$tmp_rep"
 
        # Connexion locale du Joueur A au serveur C10.42.0.153
        "$CLIENT_DUEL" "127.0.0.1" "$PORT_DUEL" "$tmp_qst" "$tmp_rep" > /dev/null 2>&1 &
 
        # Attente que le client local reçoive le bloc de la question
        attente=0
        while [ $attente -lt 50 ]; do
            [ -f "$tmp_qst" ] && grep -q "QUESTION_PRETE" "$tmp_qst" 2>/dev/null && break
            sleep 0.1; attente=$((attente + 1))
        done
 
        # Interface graphique terminal du joueur A
        clear
        echo -e "${CORAL}	        === Question $numeroquest/$total ===	${RESET}"
        echo -e "${CORAL}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    	echo -e "                 Score actuel => Toi : $score_A  |  Adversaire : $score_B "
    	echo -e "${CORAL}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${BOLD}=================================================================================${RESET}"
        echo " $question"
        echo "  [1] $C1"
        echo "  [2] $C2"
        echo "  [3] $C3"
        echo "  [4] $C4"
        echo -e "${BOLD}=================================================================================${RESET}"
        echo ""
 
        local reponse_A=""
        echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' pour quitter ❯ ${RESET} "
        read reponse_A < /dev/tty
        while [ "$reponse_A" != '1' -a "$reponse_A" != '2' -a "$reponse_A" != '3' -a "$reponse_A" != '4' -a "$reponse_A" != 'q' ]; do
            echo "Option invalide"
            sleep 1
            echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' ❯${RESET} "
            read reponse_A < /dev/tty
        done
	
	if [ "$reponse_A" = "q" ]; then
        	echo ""
        	echo -e "${BOLD}${GRAY}...Fin du match par abandon...${RESET}"
        	nettoyage_duel
        	sleep 1
        	return 0
        fi
 
        # Envoi de la réponse au client1 via le fichier tampon
        echo "$reponse_A" > "$tmp_rep"
        echo "[-] Réponse transmise. Attente du calcul de vélocité de l'adversaire..."
 
        # Attente du verdict final calculé par le serveur
        attente=0
        while [ $attente -lt 150 ]; do
            grep -q "VAINQUEUR" "$tmp_qst" 2>/dev/null && break
            sleep 0.2; attente=$((attente + 1))
        done
 
        local vainqueur_round
        vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
 
        case "$vainqueur_round" in
            A)     score_A=$((score_A + 1)); echo -e "${GREEN}\n +1 Point ! Tu as été le plus rapide !${RESET}" ;;
            B)     score_B=$((score_B + 1)); echo -e "${GREEN}\n Le Joueur B a répondu plus vite !${RESET}" ;;
            AUCUN) echo -e "${PURPLE}\n Aucun joueur n'a donné la bonne réponse.${RESET}" ;;
            *)     echo -e "${PURPLE}\n Le Joueur B a expiré (Timeout).${RESET}" ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo -e "${GOLD_AMBER}  ⏱ Écart de réactivité : $(( diff_us / 1000 )) ms${RESET}"
        fi
 
        rm -f "$tmp_qst" "$tmp_rep" /tmp/duel_srv_$$.log
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            echo -e "${BOLD}"
            read -rp "Appuyez sur [ENTREE] pour générer le round suivant..." </dev/tty
            echo -e "${RESET}"
        fi
 
        numeroquest=$((numeroquest + 1))
    done
 
    afficher_resultat_final "$score_A" "$score_B" "$total"
    nettoyage_duel
}
 
# ================================================================
# JOUEUR B — CLIENT
# ================================================================
quiz_duel_client()
{
    local ip="$1"
    local total=10
    local numeroquest=1
    local score_A=0
    local score_B=0
 
    clear
    echo -e "${BOLD}"
    echo "=== DUEL — Joueur B (Client) ==="
    echo "[*] Cible de connexion -> $ip:$PORT_DUEL"
    echo ""
    echo -e "${RESET}"
 
    while [ $numeroquest -le $total ]; do
        local tmp_qst="/tmp/duel_qstB_${numeroquest}_$$"
        local tmp_rep="/tmp/duel_repB_${numeroquest}_$$"
        rm -f "$tmp_qst" "$tmp_rep"
 
        clear
        echo -e "${BOLD}"
        echo "Connexion réseau vers le Serveur distant..."
        echo -e "${RESET}"
 
        # Tentative de poignée de main avec le serveur A
        "$CLIENT_DUEL" "$ip" "$PORT_DUEL" "$tmp_qst" "$tmp_rep" > /dev/null 2>&1 &
 
        # Attente de la réception du flux réseau de la question
        local attente=0
        while [ $attente -lt 100 ]; do
            [ -f "$tmp_qst" ] && grep -q "QUESTION_PRETE" "$tmp_qst" 2>/dev/null && break
            sleep 0.2; attente=$((attente + 1))
        done
 
        # Gestion des désynchronisations réseau : si A n'est pas prêt, on boucle sur le même round
        if [ $attente -ge 100 ]; then
            echo ""
            echo -e "${BOLD}${RED_BRIGHT} ! ! ! ${RESET}${RED_BRIGHT}Serveur distant indisponible ou round non généré.${RESET}"
            echo -e "${BOLD}Synchronisation en cours, nouvelle tentative auto..."
            killall -9 client1 2>/dev/null
            rm -f "$tmp_qst" "$tmp_rep"
            sleep 2
            continue
        fi
 
        # Affichage de la question reçue via le réseau
        clear
        echo -e "${CORAL}	        === Question $numeroquest/$total ===	${RESET}"
        echo -e "${CORAL}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    	echo -e "                  Score actuel => Adversaire : $score_A  |  Toi : $score_B               "
    	echo -e "${CORAL}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "${BOLD}=================================================================================${RESET}"
        grep -v "QUESTION_PRETE\|VAINQUEUR\|DIFF" "$tmp_qst" 2>/dev/null
        echo -e "${BOLD}=================================================================================${RESET}"
        echo ""
        
        local reponse_B=""
        echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' pour quitter ❯ ${RESET} "
        read reponse_B < /dev/tty

        while [ "$reponse_B" != '1' -a "$reponse_B" != '2' -a "$reponse_B" != '3' -a "$reponse_B" != '4' -a "$reponse_B" != 'q' ]; do
            echo "Option invalide"
            sleep 1
            echo -e -n "${BOLD}Votre réponse? (1-4) ou 'q' ❯${RESET} "
            read reponse_B < /dev/tty
        done
	
	if [ "$reponse_B" = "q" ]; then
        	echo ""
        	echo -e "${BOLD}${GRAY}...Fin du match par abandon...${RESET}"
        	nettoyage_duel
        	sleep 1
        	return 0
        fi
        
        if [ "$reponse_B" = "q" ]; then
            echo "Fin du match par abandon."
            nettoyage_duel
            return 0
        fi
 
        echo "$reponse_B" > "$tmp_rep"
        echo "[-] Réponse transmise. Attente des résultats du serveur..."
 
        # Attente du verdict réseau global
        attente=0
        while [ $attente -lt 100 ]; do
            grep -q "VAINQUEUR" "$tmp_qst" 2>/dev/null && break
            sleep 0.3; attente=$((attente + 1))
        done
 
        local vainqueur_round
        vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
 
        case "$vainqueur_round" in
            A)     score_A=$((score_A + 1)); echo -e "${GREEN}\n Le Joueur A a été plus rapide !${RESET}" ;;
            B)     score_B=$((score_B + 1)); echo -e "${GREEN}\n +1 Point ! Tu as été le plus rapide !${RESET}" ;;
            AUCUN) echo -e "${PURPLE}\n Aucun point attribué sur ce round.${RESET}" ;;
            *)     echo -e "${PURPLE}\n Erreur de synchronisation sur ce round.${RESET}" ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo -e "${GOLD_AMBER}  ⏱ Écart de réactivité : $(( diff_us / 1000 )) ms${RESET}"
        fi
 
        rm -f "$tmp_qst" "$tmp_rep"
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            echo -e "${BOLD}"
            read -rp "Appuyez sur [ENTREE] pour vous synchroniser sur le round suivant..." </dev/tty
            echo -e "${RESET}"
        fi
        
 
        numeroquest=$((numeroquest + 1))
    done
 
    afficher_resultat_final "$score_A" "$score_B" "$total"
    nettoyage_duel
}
 
afficher_resultat_final()
{
    local score_A=$1
    local score_B=$2
    local total=$3
 
    clear
    echo ""
    echo -e "${QUIZ_BLUE}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${QUIZ_BLUE}║${RESET} ${BANNER_QUIZ}     R E S U L T A T      Q U I Z Z                               ${RESET} ${QUIZ_BLUE}║${RESET}"
    echo -e "${QUIZ_BLUE}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "      ${CYAN_LIGHT}╔══════════════════════════════════════╗${RESET}"
    echo -e "      ${CYAN_LIGHT}║${RESET}    ${BOLD}${WHITE_BRIGHT}Joueur A (serveur) : ${RESET}$score_A / $total       ${CYAN_LIGHT} ║${RESET}"
    echo -e "      ${CYAN_LIGHT}║${RESET}    ${BOLD}${WHITE_BRIGHT}Joueur B (client) : ${RESET}$score_B / $total        ${CYAN_LIGHT} ║${RESET}"
    echo -e "      ${CYAN_LIGHT}╚══════════════════════════════════════╝${RESET}"
    echo ""
    
    local verdict=""
    
    if [ "$score_A" -gt "$score_B" ]; then
        echo -e "${GOLD_AMBER} ദ്ദി(˵ •̀ ᴗ - ˵ )${RESET}${BOLD}${QUIZ_BLUE} VICTOIRE de A !${RESET}"
        verdict="VICTOIRE A"
    elif [ "$score_B" -gt "$score_A" ]; then
        echo -e "${GOLD_AMBER} ദ്ദി(˵ •̀ ᴗ - ˵ )${RESET}${BOLD}${QUIZ_BLUE} VICTOIRE de B !${RESET}"
        verdict="VICTOIRE B"
    else
        echo -e "${GOLD_AMBER} ദ്ദി(˵ •̀ ᴗ - ˵ )${RESET}${BOLD}${QUIZ_BLUE} ÉGALITÉ !${RESET}"
        verdict="EGALITE"
    fi
    

    # Écrire dans l'historique duel
    echo "$(date '+%d/%m/%Y %H:%M') | $prenom | A:$score_A B:$score_B sur $total | $verdict" \
        >> MasterLin/historique_duel.txt


    echo ""
    echo -e "${BOLD}"
    read -rp "Appuyez sur ENTREE pour revenir au menu..." _ </dev/tty
    echo -e "${RESET}"
}
