#!/bin/bash
source ./Outils.sh
assist () {
if [ -n "$pid_msg1" ]; then
        kill "$pid_msg1" 2>/dev/null
        wait "$pid_msg1" 2>/dev/null
    fi
recevoir_msg "$PORT2" &
pid_msg2=$!

clear
echo " +++++++vous êtes en mode assistant+++++++"
echo "      ⚠️ Connexion via WLAN requis ⚠️ "
# Trouver l'interface Wi-Fi active
wifi_interface=$(ls /sys/class/net | grep -E '^wl')

if [ -z "$wifi_interface" ]; then
    echo "Pas de carte Wi-Fi détectée."
    exit 1
fi
# Vérifier si le Wi-Fi est connecté (operstate = up)
if [ "$(cat /sys/class/net/$wifi_interface/operstate)" = "up" ]; then
    echo "Connecté à un réseau sans fil (WLAN) via $wifi_interface"
   check_nc   
   check_audio
   check_nmap 
   echo "Sur lequel de ces pc voulez vous choisir comme assistant?"
   read -p "IP : " ip_pc2
   sleep 2
   modules_as
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

    echo "+++++++++QUIZZ++++++++"
    echo "Thème: $Theme_actuel"
    echo "Niveau: $niveau"
    echo "______________________"
    sleep 2
    #  IFS='|' sans espace — lecture correcte des champs
    # variable 'ligne' remplacée par les vraies variables lues
    while IFS='|' read -r question C1 C2 C3 C4 bonne; do
        # Ignorer lignes vides ou commentaires (filtre de sécurité)
        [ -z "$question" ] && continue
        [[ "$question" == \#* ]] && continue

        clear
        echo "=== Question $numeroquest/$total ==="
        echo "Thème : $Theme_actuel"
        echo "Score : $score"
        echo ""
        echo " $question"
        echo ""
        echo "  [1] $C1"
        echo "  [2] $C2"
        echo "  [3] $C3"
        echo "  [4] $C4"
        echo ""
        echo "Pour répondre, entrer le numéro qui correspond à ces propositions" 
        echo "ou tapez 0 pour envoyer un message à l'assistant"
        echo "...sinon tapez sur [ENTREE] pour quitter..."
        local choice
        local reponse

        while true; do
            read -r choice < /dev/tty
            [ -z "$choice" ] && continue
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
                    # si la réponse est vide, c-à-d le joueur a appuyé sur entrée, on quitte
                    if [ -z "$reponse" ]; then 
                        echo ""
                        echo "Abandon du quiz... Retour au menu principal."
                        sleep 2
                        return # On stoppe la fonction et on retourne au menu principal
                    fi	
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
}
