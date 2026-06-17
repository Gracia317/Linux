#!/bin/bash
 
affiche_duel()
{
    clear
    echo "================================="
    echo "            MODE DUEL            "
    echo "================================="
    echo ""
    echo "    [1] Lancer un round duel    (Joueur A / Serveur)"
    echo "    [2] Rejoindre un round duel (Joueur B / Client)"
    echo "    [3] Retour au menu principal"
    echo ""
    echo -n "Entrez votre choix : "
    read safidy
 
    case "$safidy" in
        1)
            IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1)
            [ -z "$IP_LOCAL" ] && IP_LOCAL=$(hostname -I | awk '{print $1}')
            
            echo ""
            echo "========================================="
            echo "  TON IP RÉSEAU ACTIVE : $IP_LOCAL"
            echo "  Port de Duel         : $PORT_DUEL"
            echo "========================================="
            echo "[*] Donne cette IP exacte au Joueur B."
            echo ""
            quiz_duel_serveur
            ;;
        2)
            local ip_serveur=""
            echo "Entrez l'IP du serveur (Joueur A) (Vous devez être sur le même réseau): "
            echo "ou tapez sur ENTREE pour quitter..."
            read ip_serveur
            if [ -z "$ip_serveur" ]; then
                echo "IP vide. Annulation."
                sleep 1
                return
            fi
            quiz_duel_client "$ip_serveur"
            ;;
        3)
            return 0
            ;;
        *)
            echo "Choix invalide."
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
        echo "Fichier questionsduel.csv introuvable !"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    mapfile -t QUESTIONS < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n 10) #mapfile est comme un tableau portant le nom QUESTIONS qui stocke les 10 lignes aléatoires
 
    local total=${#QUESTIONS[@]} #total = au nombre case du tableau QUESTIONS généré par mapfile
    if [ "$total" -eq 0 ]; then
        echo "Aucune question trouvée dans le fichier CSV."
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    local numeroquest=1
    local score_A=0
    local score_B=0
 
    echo ""
    echo ""
    echo "=== DUEL — Joueur A (Serveur) ==="
    echo "[*] En attente du Joueur B..."
    echo ""
    read -rp "Appuyez sur ENTREE pour ouvrir la session de jeu... " </dev/tty
 
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
 
        # Connexion locale du Joueur A au serveur C
        "$CLIENT_DUEL" "127.0.0.1" "$PORT_DUEL" "$tmp_qst" "$tmp_rep" > /dev/null 2>&1 &
 
        # Attente que le client local reçoive le bloc de la question
        attente=0
        while [ $attente -lt 50 ]; do
            [ -f "$tmp_qst" ] && grep -q "QUESTION_PRETE" "$tmp_qst" 2>/dev/null && break
            sleep 0.1; attente=$((attente + 1))
        done
 
        # Interface graphique terminal du joueur A
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score actuel => Toi : $score_A  |  Adversaire : $score_B)"
        echo "-----------------------------------------"
        echo " $question"
        echo "  [1] $C1"
        echo "  [2] $C2"
        echo "  [3] $C3"
        echo "  [4] $C4"
        echo "-----------------------------------------"
        echo ""
 
        local reponse_A=""
        read -rp "Votre réponse (1-4) ou 'q' pour abandonner : " reponse_A </dev/tty
        while [[ "$reponse_A" != [1-4] && "$reponse_A" != "q" ]]; do
            read -rp "Saisie incorrecte (1-4/q) : " reponse_A </dev/tty
        done

        if [ "$reponse_A" = "q" ]; then
            echo "Fin du match par abandon."
            nettoyage_duel
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
            A)     score_A=$((score_A + 1)); echo -e "\n +1 Point ! Tu as été le plus rapide !" ;;
            B)     score_B=$((score_B + 1)); echo -e "\n Le Joueur B a répondu plus vite !" ;;
            AUCUN) echo -e "\n Aucun joueur n'a donné la bonne réponse." ;;
            *)     echo -e "\n Le Joueur B a expiré (Timeout)." ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo "  ⏱ Écart de réactivité : $(( diff_us / 1000 )) ms"
        fi
 
        rm -f "$tmp_qst" "$tmp_rep" /tmp/duel_srv_$$.log
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            read -rp "Appuyez sur [ENTREE] pour générer le round suivant..." </dev/tty
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
    echo "=== DUEL — Joueur B (Client) ==="
    echo "[*] Cible de connexion -> $ip:$PORT_DUEL"
    echo ""
 
    while [ $numeroquest -le $total ]; do
        local tmp_qst="/tmp/duel_qstB_${numeroquest}_$$"
        local tmp_rep="/tmp/duel_repB_${numeroquest}_$$"
        rm -f "$tmp_qst" "$tmp_rep"
 
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score actuel => Adversaire : $score_A  |  Toi : $score_B)"
        echo "-----------------------------------------"
        echo "Connexion réseau vers le Serveur distant..."
 
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
            echo "⚠️  Serveur distant indisponible ou round non généré."
            echo "Synchronisation en cours, nouvelle tentative automatique..."
            killall -9 client1 2>/dev/null
            rm -f "$tmp_qst" "$tmp_rep"
            sleep 2
            continue
        fi
 
        # Affichage de la question reçue via le réseau
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score actuel => Joueur A : $score_A  |  Toi : $score_B)"
        echo "-----------------------------------------"
        grep -v "QUESTION_PRETE\|VAINQUEUR\|DIFF" "$tmp_qst" 2>/dev/null
        echo "-----------------------------------------"
        echo ""
 
        local reponse_B=""
        read -rp "Votre réponse (1-4) ou 'q' pour abandonner : " reponse_B </dev/tty
        while [[ "$reponse_B" != [1-4] && "$reponse_B" != "q" ]]; do
            read -rp "Saisie incorrecte (1-4/q) : " reponse_B </dev/tty
        done
        
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
            A)     score_A=$((score_A + 1)); echo -e "\n Le Joueur A a été plus rapide !" ;;
            B)     score_B=$((score_B + 1)); echo -e "\n +1 Point ! Tu as été le plus rapide !" ;;
            AUCUN) echo -e "\n Aucun point attribué sur ce round." ;;
            *)     echo -e "\n Erreur de synchronisation sur ce round." ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo "  ⏱ Écart de réactivité : $(( diff_us / 1000 )) ms"
        fi
 
        rm -f "$tmp_qst" "$tmp_rep"
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            read -rp "Appuyez sur [ENTREE] pour vous synchroniser sur le round suivant..." </dev/tty
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
    echo "══════════════════════════"
    echo "   RÉSULTAT FINAL DU DUEL"
    echo "══════════════════════════"
    echo "  Joueur A (serveur) : $score_A / $total"
    echo "  Joueur B (client)  : $score_B / $total"
    echo ""
    
    local verdict=""
    
    if [ "$score_A" -gt "$score_B" ]; then
        echo "  🏆 VICTOIRE de A !"
        verdict="VICTOIRE A"
    elif [ "$score_B" -gt "$score_A" ]; then
        echo "  🏆 VICTOIRE de B !"
        verdict="VICTOIRE B"
    else
        echo "  🤝 ÉGALITÉ !"
        verdict="EGALITE"
    fi
    

    # Écrire dans l'historique duel
    echo "$(date '+%d/%m/%Y %H:%M') | $prenom | A:$score_A B:$score_B sur $total | $verdict" \
        >> MasterLin/historique_duel.txt


    echo ""
    read -rp "Appuyez sur ENTREE pour revenir au menu..." _ </dev/tty
}
