#!/bin/bash
# duel1.sh — Version finale sans erreur de syntaxe et synchronisée

affiche_duel()
{
    PORT_DUEL=8080
    SERVEUR_DUEL="./serveur1"
    CLIENT_DUEL="./client1"

    while true; do
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
                echo ""
                echo "[*] Configuration du Joueur A (Serveur)..."
                
                # Détection ultra-fiable de l'IP locale de la machine
                IP_LOCAL=$(hostname -I | awk '{print $1}')
                if [ -z "$IP_LOCAL" ]; then
                    IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -1)
                fi
                if [ -z "$IP_LOCAL" ]; then
                    IP_LOCAL="127.0.0.1"
                fi

                echo "========================================="
                echo "🌐 TON IP RÉSEAU : $IP_LOCAL"
                echo "========================================="
                echo "[*] Donne cette adresse exacte au Joueur B."
                echo ""
                quiz_duel_serveur
                ;;
            2)
                echo ""
                local ip_serveur=""
                read -p "Entrez l'IP du serveur (Joueur A) : " ip_serveur
                if [ -z "$ip_serveur" ]; then
                    echo "⚠️ L'adresse IP ne peut pas être vide !"
                    sleep 1.5
                    continue
                fi
                echo ""
                quiz_duel_client "$ip_serveur"
                ;;
            3)
                return 0
                ;;
            *)
                echo "❌ Choix invalide !"
                sleep 1
                ;;
        esac
    done
}

compiler_duel()
{
    if [ ! -f "./serveur1" ] || [ ! -f "./client1" ]; then
        echo "[*] Compilation des moteurs C..."
        gcc -o serveur1 serveur1.c 2>/dev/null
        gcc -o client1 client1.c 2>/dev/null
        if [ ! -f "./serveur1" ] || [ ! -f "./client1" ]; then
            echo "❌ ERREUR : Échec de la compilation."
            read -rp "Appuyez sur ENTREE..." </dev/tty
            return 1
        fi
    fi
    return 0
}

quiz_duel_serveur()
{
    compiler_duel || return 1

    local fichier_question="questions/questionsduel.csv"
    [ ! -f "$fichier_question" ] && fichier_question="questionsduel.csv"

    if [ ! -f "$fichier_question" ]; then
        echo "❌ Fichier questionsduel.csv introuvable !"
        read -rp "Appuyez sur ENTREE..." </dev/tty
        return 1
    fi

    mapfile -t QUESTIONS < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n 10)
    local total=${#QUESTIONS[@]}

    local numeroquest=1
    local score_A=0
    local score_B=0

    read -rp "Appuyez sur ENTREE pour démarrer la partie..." </dev/tty

    for ligne in "${QUESTIONS[@]}"; do
        IFS='|' read -r question C1 C2 C3 C4 bonne <<< "$ligne"

        killall -9 serveur1 client1 2>/dev/null
        sleep 0.3

        # 1. On lance le serveur
        "$SERVEUR_DUEL" "$PORT_DUEL" "$bonne" "$ligne" > /dev/null 2>&1 &
        local SERVEUR_PID=$!
        
        # 2. TEMPORISATION : On laisse le temps au serveur d'ouvrir son port
        sleep 0.6

        local tmp_qst_A="/tmp/duel_qst_A_${numeroquest}_$$"
        local tmp_rep_A="/tmp/duel_rep_A_${numeroquest}_$$"
        rm -f "$tmp_qst_A" "$tmp_rep_A"

        # 3. Le client local A se connecte
        "$CLIENT_DUEL" "127.0.0.1" "$PORT_DUEL" "$tmp_qst_A" "$tmp_rep_A" > /dev/null 2>&1 &
        local CLIENT_A_PID=$!

        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Scores -> A: $score_A | B: $score_B)"
        echo ""
        echo "Attente que le Joueur B lise et réponde..."

        # Attente de la synchronisation réseau
        local timeout=0
        while [ $timeout -lt 100 ]; do
            if [ -f "$tmp_qst_A" ] && grep -q "QUESTION_PRETE" "$tmp_qst_A" 2>/dev/null; then
                break
            fi
            sleep 0.1
            timeout=$((timeout + 1))
        done

        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Scores -> A: $score_A | B: $score_B)"
        echo ""
        if [ -f "$tmp_qst_A" ]; then
            grep -v "QUESTION_PRETE\|VAINQUEUR\|DIFF" "$tmp_qst_A" 2>/dev/null
        else
            echo "👉 QUESTION : $question"
            echo "  [1] $C1"
            echo "  [2] $C2"
            echo "  [3] $C3"
            echo "  [4] $C4"
        fi
        echo ""

        local reponse_A=""
        read -rp "Votre réponse (1-4) : " reponse_A </dev/tty
        while [[ "$reponse_A" != [1-4] ]]; do
            read -rp "Invalide. Tapez (1-4) : " reponse_A </dev/tty
        done

        echo "$reponse_A" > "$tmp_rep_A"
        
        wait $SERVEUR_PID 2>/dev/null
        wait $CLIENT_A_PID 2>/dev/null

        local vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst_A" 2>/dev/null | cut -d':' -f2)
        case "$vainqueur_round" in
            A) score_A=$((score_A + 1)); echo -e "\n✅ Tu gagnes le point !";;
            B) score_B=$((score_B + 1)); echo -e "\n❌ Le Joueur B a été plus rapide.";;
            *) echo -e "\n😐 Aucun point alloué.";;
        esac

        rm -f "$tmp_qst_A" "$tmp_rep_A"
        echo ""
        read -rp "Appuyez sur ENTREE pour continuer..." </dev/tty
        numeroquest=$((numeroquest + 1))
    done

    afficher_resultat_final "$score_A" "$score_B" "$total"
}

quiz_duel_client()
{
    local ip="$1"
    local total=10
    local numeroquest=1
    local score_A=0
    local score_B=0

    for i in $(seq 1 $total); do
        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Scores -> A: $score_A | B: $score_B)"
        echo ""
        echo "Connexion en cours à l'adresse $ip..."

        local tmp_qst_B="/tmp/duel_qst_B_${numeroquest}_$$"
        local tmp_rep_B="/tmp/duel_rep_B_${numeroquest}_$$"
        rm -f "$tmp_qst_B" "$tmp_rep_B"

        local connecte=0
        for essai in 1 2 3 4 5; do
            ./client1 "$ip" 8080 "$tmp_qst_B" "$tmp_rep_B" > /dev/null 2>&1 &
            local CLIENT_PID=$!
            sleep 0.3
            if kill -0 $CLIENT_PID 2>/dev/null; then
                connecte=1
                break
            fi
            sleep 0.3
        done

        local timeout=0
        while [ $timeout -lt 100 ]; do
            if [ -f "$tmp_qst_B" ] && grep -q "QUESTION_PRETE" "$tmp_qst_B" 2>/dev/null; then
                break
            fi
            sleep 0.1
            timeout=$((timeout + 1))
        done

        clear
        echo "=== Question $numeroquest/$total ==="
        echo "(Scores -> A: $score_A | B: $score_B)"
        echo ""
        
        if [ -f "$tmp_qst_B" ] && grep -q "QUESTION_PRETE" "$tmp_qst_B" 2>/dev/null; then
            grep -v "QUESTION_PRETE\|VAINQUEUR\|DIFF" "$tmp_qst_B" 2>/dev/null
            echo ""
            
            local reponse_B=""
            read -rp "Votre réponse (1-4) : " reponse_B </dev/tty
            while [[ "$reponse_B" != [1-4] ]]; do
                read -rp "Invalide. Tapez (1-4) : " reponse_B </dev/tty
            done

            echo "$reponse_B" > "$tmp_rep_B"
            echo "Envoyé ! Calcul des scores..."
            wait $CLIENT_PID 2>/dev/null

            local vainqueur_round=$(grep -o 'VAINQUEUR:[A-Z]*' "$tmp_qst_B" 2>/dev/null | cut -d':' -f2)
            case "$vainqueur_round" in
                A) score_A=$((score_A + 1)); echo -e "\n❌ Le Joueur A a été plus rapide.";;
                B) score_B=$((score_B + 1)); echo -e "\n✅ Tu gagnes le point !";;
                *) echo -e "\n😐 Aucun point.";;
            esac
        else
            echo "⚠️ Problème de synchronisation réseau détecté."
            echo "Réalignement automatique en cours, veuillez patienter..."
            kill -9 $CLIENT_PID 2>/dev/null
            sleep 1
            i=$((i - 1))
            numeroquest=$((numeroquest - 1))
            rm -f "$tmp_qst_B" "$tmp_rep_B"
            continue
        fi

        rm -f "$tmp_qst_B" "$tmp_rep_B"
        echo ""
        read -rp "Appuyez sur ENTREE pour continuer..." </dev/tty
        numeroquest=$((numeroquest + 1))
    done
    
    afficher_resultat_final "$score_A" "$score_B" "$total"
}

afficher_resultat_final()
{
    clear
    echo "══════════════════════════"
    echo "   RÉSULTAT FINAL DU DUEL"
    echo "══════════════════════════"
    echo "  Joueur A : $1 / $3"
    echo "  Joueur B : $2 / $3"
    echo ""
    read -rp "Appuyez sur ENTREE pour retourner au menu..." _ </dev/tty
}
