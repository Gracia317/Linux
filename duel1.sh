#!/bin/bash
# duel1.sh — Mode duel réseau
# projet2.sh définit : SERVEUR_DUEL, CLIENT_DUEL, PORT_DUEL
 
affiche_duel()
{
    clear
    echo "================================="
    echo "        MODE DUEL NETWORK        "
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
            IP_LOCAL=$(hostname -I 2>/dev/null | awk '{print $1}')
            [ -z "$IP_LOCAL" ] && IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
            [ -z "$IP_LOCAL" ] && IP_LOCAL="127.0.0.1"
            echo ""
            echo "========================================="
            echo "  TON IP RÉSEAU : $IP_LOCAL"
            echo "  Port          : $PORT_DUEL"
            echo "========================================="
            echo "[*] Donne cette IP au Joueur B."
            echo ""
            quiz_duel_serveur
            ;;
        2)
            local ip_serveur=""
            read -p "Entrez l'IP du serveur (Joueur A) : " ip_serveur
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
        echo "[*] Compilation..."
        gcc -o serveur1 serveur1.c 2>/dev/null
        gcc -o client1 client1.c 2>/dev/null
        if [ ! -f "./serveur1" ] || [ ! -f "./client1" ]; then
            echo "ERREUR : Compilation échouée."
            read -rp "Appuyez sur ENTREE..." </dev/tty
            return 1
        fi
        echo "Compilation OK."
    fi
    return 0
}
 
# ================================================================
# JOUEUR A — SERVEUR
# ================================================================
quiz_duel_serveur()
{
    compiler_duel || return 1
 
    local fichier_question="questions/questionsduel.csv"
    [ ! -f "$fichier_question" ] && fichier_question="questionsduel.csv"
    if [ ! -f "$fichier_question" ]; then
        echo "Fichier questionsduel.csv introuvable !"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    # Charger exactement 10 questions
    mapfile -t QUESTIONS < <(grep -v '^#' "$fichier_question" \
        | grep -v '^[[:space:]]*$' | shuf | head -n 10)
 
    local total=${#QUESTIONS[@]}
    if [ "$total" -eq 0 ]; then
        echo "Aucune question chargée !"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi
 
    local numeroquest=1
    local score_A=0
    local score_B=0
 
    clear
    echo "=== DUEL — Joueur A ==="
    echo "[*] IP : $(hostname -I 2>/dev/null | awk '{print $1}')  Port : $PORT_DUEL"
    echo "[*] Attends que le Joueur B lance son côté."
    echo ""
    read -rp "Appuyez sur ENTREE pour démarrer... " </dev/tty
 
    mkdir -p duel
 
    # Boucle while (plus fiable que for pour contrôler le compteur)
    while [ $numeroquest -le $total ]; do
        local idx=$((numeroquest - 1))
        local ligne="${QUESTIONS[$idx]}"
        IFS='|' read -r question C1 C2 C3 C4 bonne <<< "$ligne"
 
        # Tuer toute instance précédente proprement
        kill $SERVEUR_PID 2>/dev/null
        wait $SERVEUR_PID 2>/dev/null
        sleep 0.3
 
        # Lancer serveur1 pour ce round
        "$SERVEUR_DUEL" "$PORT_DUEL" "$bonne" "$ligne" > /tmp/duel_srv_$$.log 2>&1 &
        SERVEUR_PID=$!
 
        # Attendre SERVEUR_PRET
        local attente=0
        while [ $attente -lt 30 ]; do
            grep -q "SERVEUR_PRET" /tmp/duel_srv_$$.log 2>/dev/null && break
            sleep 0.2; attente=$((attente + 1))
        done
        if [ $attente -ge 30 ]; then
            echo "ERREUR: serveur non démarré. On réessaie..."
            sleep 1; continue
        fi
 
        # Fichiers temporaires pour ce round
        local tmp_qst="/tmp/duel_qstA_${numeroquest}_$$"
        local tmp_rep="/tmp/duel_repA_${numeroquest}_$$"
        rm -f "$tmp_qst" "$tmp_rep"
 
        # Connexion de A en local (background)
        "$CLIENT_DUEL" "127.0.0.1" "$PORT_DUEL" "$tmp_qst" "$tmp_rep" > /dev/null 2>&1 &
        local CLIENT_A_PID=$!
 
        # Attendre que A soit connecté (question reçue)
        attente=0
        while [ $attente -lt 50 ]; do
            [ -f "$tmp_qst" ] && grep -q "QUESTION_PRETE" "$tmp_qst" 2>/dev/null && break
            sleep 0.1; attente=$((attente + 1))
        done
 
        # Afficher la question à A
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score → A : $score_A  |  B : $score_B)"
        echo ""
        echo " $question"
        echo "  [1] $C1"
        echo "  [2] $C2"
        echo "  [3] $C3"
        echo "  [4] $C4"
        echo ""
 
        # Lire la réponse de A
        local reponse_A=""
        read -rp "Votre réponse (1-4) : " reponse_A </dev/tty
        while [[ "$reponse_A" != [1-4] ]]; do
            read -rp "Invalide. Tapez (1-4) : " reponse_A </dev/tty
        done
 
        # Écrire la réponse → client1 la lit et l'envoie au serveur
        echo "$reponse_A" > "$tmp_rep"
 
        echo "En attente de la réponse de B..."
 
        # Attendre que le résultat arrive dans tmp_qst
        attente=0
        while [ $attente -lt 100 ]; do
            grep -q "VAINQUEUR" "$tmp_qst" 2>/dev/null && break
            sleep 0.3; attente=$((attente + 1))
        done
 
        wait $CLIENT_A_PID 2>/dev/null
        wait $SERVEUR_PID 2>/dev/null
 
        # Extraire et afficher le résultat
        local vainqueur_round
        vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
 
        case "$vainqueur_round" in
            A)     score_A=$((score_A + 1)); echo ""; echo "✅ Tu gagnes ce round !" ;;
            B)     score_B=$((score_B + 1)); echo ""; echo "❌ Le Joueur B a été plus rapide." ;;
            AUCUN) echo ""; echo "😐 Aucun bon. Pas de point." ;;
            *)     echo ""; echo "⚠️  Résultat inconnu." ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo "  ⏱ Écart : $(( diff_us / 1000 )) ms"
        fi
 
        echo ""
        echo "Score → A : $score_A  |  B : $score_B"
        rm -f "$tmp_qst" "$tmp_rep" /tmp/duel_srv_$$.log
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            read -rp "Appuyez sur ENTREE pour la suite..." </dev/tty
        fi
 
        numeroquest=$((numeroquest + 1))
    done
 
    afficher_resultat_final "$score_A" "$score_B" "$total"
}
 
# ================================================================
# JOUEUR B — CLIENT
# Boucle while (pas for) pour contrôler le compteur proprement
# ================================================================
quiz_duel_client()
{
    local ip="$1"
    local total=10
    local numeroquest=1
    local score_A=0
    local score_B=0
 
    clear
    echo "=== DUEL — Joueur B ==="
    echo "[*] Serveur : $ip:$PORT_DUEL"
    echo ""
 
    while [ $numeroquest -le $total ]; do
 
        local tmp_qst="/tmp/duel_qstB_${numeroquest}_$$"
        local tmp_rep="/tmp/duel_repB_${numeroquest}_$$"
        rm -f "$tmp_qst" "$tmp_rep"
 
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score → A : $score_A  |  B : $score_B)"
        echo ""
        echo "Connexion au serveur $ip..."
 
        # Lancer client1 en background
        "$CLIENT_DUEL" "$ip" "$PORT_DUEL" "$tmp_qst" "$tmp_rep" > /dev/null 2>&1 &
        local CLIENT_B_PID=$!
 
        # Attendre la question (timeout 30s)
        local attente=0
        while [ $attente -lt 150 ]; do
            [ -f "$tmp_qst" ] && grep -q "QUESTION_PRETE" "$tmp_qst" 2>/dev/null && break
            sleep 0.2; attente=$((attente + 1))
        done
 
        # Si timeout → on réessaie CE round (compteur inchangé)
        if [ $attente -ge 150 ]; then
            echo ""
            echo "Connexion échouée. Vérifiez que le Joueur A a bien lancé son côté."
            echo "Nouvelle tentative dans 3 secondes..."
            kill $CLIENT_B_PID 2>/dev/null
            wait $CLIENT_B_PID 2>/dev/null
            rm -f "$tmp_qst" "$tmp_rep"
            sleep 3
            continue   # ← on refait le même round (numeroquest inchangé)
        fi
 
        # Afficher la question
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Score → A : $score_A  |  B : $score_B)"
        echo ""
        grep -v "QUESTION_PRETE\|VAINQUEUR\|DIFF" "$tmp_qst" 2>/dev/null
        echo ""
 
        # Lire la réponse de B
        local reponse_B=""
        read -rp "Votre réponse (1-4) : " reponse_B </dev/tty
        while [[ "$reponse_B" != [1-4] ]]; do
            read -rp "Invalide. Tapez (1-4) : " reponse_B </dev/tty
        done
 
        # Écrire la réponse → client1 la lit et l'envoie
        echo "$reponse_B" > "$tmp_rep"
 
        echo "Réponse envoyée. Attente du résultat..."
 
        # Attendre le résultat
        attente=0
        while [ $attente -lt 100 ]; do
            grep -q "VAINQUEUR" "$tmp_qst" 2>/dev/null && break
            sleep 0.3; attente=$((attente + 1))
        done
 
        wait $CLIENT_B_PID 2>/dev/null
 
        # Extraire et afficher le résultat
        local vainqueur_round
        vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
 
        case "$vainqueur_round" in
            A)     score_A=$((score_A + 1)); echo ""; echo "❌ Le Joueur A a été plus rapide." ;;
            B)     score_B=$((score_B + 1)); echo ""; echo "✅ Tu gagnes ce round !" ;;
            AUCUN) echo ""; echo "😐 Aucun bon. Pas de point." ;;
            *)     echo ""; echo "⚠️  Résultat inconnu." ;;
        esac
 
        local diff_us
        diff_us=$(grep -o 'DIFF:[0-9]*' "$tmp_qst" 2>/dev/null | cut -d':' -f2)
        if [ -n "$diff_us" ] && [ "$diff_us" != "0" ]; then
            echo "  ⏱ Écart : $(( diff_us / 1000 )) ms"
        fi
 
        echo ""
        echo "Score → A : $score_A  |  B : $score_B"
        rm -f "$tmp_qst" "$tmp_rep"
 
        if [ $numeroquest -lt $total ]; then
            echo ""
            read -rp "Appuyez sur ENTREE pour la suite..." </dev/tty
        fi
 
        numeroquest=$((numeroquest + 1))   # ← avance seulement si round réussi
    done
 
    afficher_resultat_final "$score_A" "$score_B" "$total"
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
    echo "  Joueur A : $score_A / $total"
    echo "  Joueur B : $score_B / $total"
    echo ""
    if [ "$score_A" -gt "$score_B" ]; then
        echo "  🏆 VICTOIRE de A !"
    elif [ "$score_B" -gt "$score_A" ]; then
        echo "  🏆 VICTOIRE de B !"
    else
        echo "  🤝 ÉGALITÉ !"
    fi
    echo ""
    read -rp "Appuyez sur ENTREE pour revenir au menu..." _ </dev/tty
}
 

