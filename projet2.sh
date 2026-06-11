#!/bin/bash
#script bash du jeu

source ./score.sh	#contient les fichier de progressions, et score etc;;;
source ./Outil.sh	# port et ip, barre de chargem et notif, notif, checknmap, installation nmap, nc
source ./Menu.sh
source ./assist.sh
source ./duel1.sh
SERVEUR_DUEL="./serveur1"
CLIENT_DUEL="./client1"
PORT_DUEL=8080

if [ "$EUID" -ne 0 ]; then
    echo "Erreur : Ce script doit impérativement être lancé avec 'sudo -E'."
    exit 1
fi
 if [ -n "$SUDO_USER" ]; then
    VRAI_HOME=$(echo "/home/$SUDO_USER")
else
    VRAI_HOME=$HOME
fi
#on autorise la récéption des messages dès le lancement du script
mesg y 2>/dev/null

ip_pc2=""
prenom=""
Theme_actuel=""
numero_theme=""
minimum=60
PORT1=6855
PORT2=5586

recevoir_msg "$PORT1" &
pid_msg1=$!

if [ ! -d "$VRAI_HOME/.ssh" ];then
mkdir -p "$VRAI_HOME/.ssh" && chmod 700 "$VRAI_HOME/.ssh"
fi
if [ ! -f "$VRAI_HOME/.ssh/authorized_keys" ];then
touch "$VRAI_HOME/.ssh/authorized_keys" && chmod 600 "$VRAI_HOME/.ssh/authorized_keys"
chown "$SUDO_USER:$SUDO_USER" "$VRAI_HOME/.ssh/authorized_keys"
fi

connexion_joueur() {
    local prenom=$1
    echo -n "Joueur existant. Entrer le mot de passe: "
    read -s mot_de_passe    
    echo ""
    
    local saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    local stocke=$(grep "^$prenom:" MasterLin/password.txt | cut -d ':' -f2)
   
    local tentative=0
    while [ "$saisi" != "$stocke" ]; do
        tentative=$(( tentative + 1 ))
        if [ "$tentative" -eq 5 ]; then
            echo "Mot de passe oublié après 5 tentatives?"
            echo "Veuillez saisir un tout nouveau mot de passe:"
            read -s mot_de_passe
            echo ""
            nouveau=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
            
            sed -i "s/^$prenom:.*/$prenom:$nouveau/" MasterLin/password.txt
            
            echo "Mot de passe changé avec succès !"
            break
        fi

        echo "Mot de passe incorrect. Réessayer (${tentative}/5): "
        read -s mot_de_passe
        echo ""
        saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    done
    
    echo "Rebonjour $prenom !"
}

accueil() {
    clear
    echo "================================"
    echo "      ****MasterLin**** "
    echo " "
    echo " Quizz et apprentissage amusant "
    echo " "
    echo "--------------------------------"

    if [ ! -d MasterLin ]; then
        mkdir MasterLin
        touch MasterLin/password.txt
        chmod 600 MasterLin/password.txt
    fi

    echo "Les joueurs existants:"
    awk -F ':' '{printf "==>%s\n",$1}' MasterLin/password.txt
    echo ""

    echo "Entrer votre nom de joueur ou créez-en un nouveau:"
    read prenom

    # Si le joueur existe
    if grep -q "^$prenom:" MasterLin/password.txt ; then
        connexion_joueur "$prenom"
    else
        echo "Ce nom ne correspond à aucun joueur existant. Créer un nouveau joueur?"
        echo " [o] oui    [n] non    [autre] pour quitter"
        read noui
        case $noui in
            o|O)
                echo -n "Entrez votre mot de passe: "
                read -s mot_de_passe
                echo ""
                pwd_hash=$(echo -n "$mot_de_passe" | sha256sum | cut -d ' ' -f1)
                echo "$prenom:$pwd_hash" >> MasterLin/password.txt
                echo "Hello $prenom ! Are you ready ?"
                ;;
                
            n|N)
                echo "Veuillez entrer un nom de joueur existant..."
                read prenom
                if grep -q "^$prenom:" MasterLin/password.txt ; then
                    connexion_joueur "$prenom"
                else
                    echo "Joueur introuvable. Fin du programme."
                    exit 1
                fi
                ;;
                
            *)
                echo "Choix invalide."
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
        echo "================================"
        echo "      ****MasterLin****      "
        echo "================================"
        echo "		[1] Jouer"
        echo "  	[2] Message" 
        echo "		[3] A propos"	
        echo "		[4] Historique"	
        echo "		[5] Quitter"
        echo "Entrez votre choix:"
        read choix
    
        while [ -z "$choix" ]; do
            echo "Redéfinissez votre choix"
            read choix
        done

        while [ "$choix" != '1' -a "$choix" != '2' -a "$choix" != '3' -a "$choix" != '4' -a "$choix" != '5' ]; do
            echo "Redéfinissez votre choix"
            read choix
        done

        if [ "$choix" = '1' ]; then
            clear
            Mode
            
        elif [ "$choix" = '2' ];then
        	clear
        	reponse
        	sleep 2
    
        elif [ "$choix" = '3' ]; then
            clear
            echo "		=======❓A propos❓======"
            echo "	------------------------------------------"
            echo "	|MasterLin — Jeu de quiz Linux           |"
            echo "	|3 modules : fichiers, texte, permissions|"
            echo "	|3 niveaux par module                    |"
            echo "	|Questions aléatoires a chaque partie    |"
            echo "	|#en cours# mode assistance et duel      |"
            echo "	-----------------------------------------"
            echo "		========================="
            echo "Appuyez sur Entree pour revenir..."
            read

        elif [ "$choix" = '4' ]; then
            clear
            echo "====HISTORIQUE===="
            echo ""
            echo "	[1] Historique solo"
            echo "	[2] Historique duel"
            echo ""
            read histo
            
            if [ "$histo" = '1' ]; then
            	if [ -f MasterLin/historique.txt ]; then
                	cat MasterLin/historique.txt
            	else
            	    echo "Pas de scores pour le moment"
            	fi
        	echo ""
        	echo "Appuyer sur Entrer pour revenir"
            	read
            elif [ "$histo" = '2' ]; then
            	if [ -f MasterLin/historique_duel.txt ]; then
                	cat MasterLin/historique_duel.txt
            	else
            	    echo "Pas de duel pour le moment"
            	fi
        	echo ""
        	echo "Appuyer sur Entrer pour revenir"
            	read
	   else
	   	echo "Choix invalide"
	   	read histo
	   fi
            	
        elif [ "$choix" = '5' ]; then
        	echo " "
        	rm -f /tmp/cle_recue.tmp 
        	echo "See you"
            	sleep 2
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

    echo "+++++++++QUIZZ++++++++"
    echo "Thème: $Theme_actuel"
    echo "Niveau: $niveau"
    echo "______________________"
    sleep 2

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
        echo -n "Votre réponse? (1-4) ou 'q' pour quitter : "
        read reponse < /dev/tty

        while [ "$reponse" != '1' -a "$reponse" != '2' -a "$reponse" != '3' -a "$reponse" != '4' -a "$reponse" != 'q' ]; do
            echo "Option invalide"
            sleep 1
            echo -n "Votre réponse? (1-4) : "
            read reponse < /dev/tty
        done
        
        if [ "$reponse" = "q" ]; then
        	echo "...Vous abandonnez la partie..."
        	sleep 1
        	return 0
        fi

        if [ "$reponse" = "$bonne" ]; then
            echo ""
            echo "Bonne réponse ! +1 point"
            notif "Bien joué !"
            score=$((score + 1))
        else
            local texte_bonne=""
            if [ "$bonne" = "1" ]; then texte_bonne="$C1"
            elif [ "$bonne" = "2" ]; then texte_bonne="$C2"
            elif [ "$bonne" = "3" ]; then texte_bonne="$C3"
            elif [ "$bonne" = "4" ]; then texte_bonne="$C4"
            fi
            echo ""
            echo " Mauvaise réponse."
            echo "La bonne réponse était : $texte_bonne"
            notif "Pas de chance !"
        fi

        numeroquest=$((numeroquest + 1))
        sleep 3

    # pipeline propre — grep filtre, shuf mélange, head limite à $total
    done < <(grep -v '^#' "$fichier_question" | grep -v '^[[:space:]]*$' | shuf | head -n $total)

    resultat "$score" "$total" "$niveau"
}

accueil
menu_principal

##comparaison avec projet.sh que veut dire les lignes 252 à 255
