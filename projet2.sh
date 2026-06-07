#!/bin/bash
#script bash du jeu

source ./outil2.sh	#notif et bare de chargement
source ./score.sh	#contient les fichier de progressions, et score etc;;;
source ./duel1.sh    #contient compile_duel et affiche_duel
SERVEUR_DUEL="./serveur1"
CLIENT_DUEL="./client1"
PORT_DUEL=8080
PORT_HISTORIQUE=8081

prenom=""
Theme_actuel=""
numero_theme=""
minimum=60

accueil()
{
clear
echo "================================"
echo "      ****MasterLin****      "
echo " "
echo " Quizz et apprentissage amusant "
echo " "
echo "--------------------------------"

if [ ! -d MasterLin ]; then
    mkdir MasterLin
    touch MasterLin/password.txt
    chmod 600 MasterLin/password.txt
fi

echo "Entrer votre prénom:"
read prenom

if grep -q "^$prenom:" MasterLin/password.txt ; then
    echo -n "Joueur existant. Entrer le mot de passe: "
    read -s mot_de_passe	
    echo ""
    
    saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    stocke=$(grep "^$prenom:" MasterLin/password.txt | cut -d ':' -f2)
    
   while [ "$saisi" != "$stocke" ]; do
        echo "Mot de passe incorrect. Réessayer: "
        read -s mot_de_passe
        echo ""
        saisi=$(echo -n "$mot_de_passe" | sha256sum | cut -d' ' -f1)
    done
    
    echo "Rebonjour $prenom !"
else
    echo "Nouveau joueur. Entrez votre mot de passe:"
    read -s mot_de_passe
    echo ""
    pwd_hash=$(echo -n "$mot_de_passe" | sha256sum | cut -d ' ' -f1)
    echo "$prenom:$pwd_hash" >> MasterLin/password.txt
    echo "Hello $prenom ! Are you ready ?"
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
        	echo "****************En cours*****************************"
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
        echo "See you"
            sleep 2
            clear
            exit 0
        fi
    done
}

Mode () {
while true; do
	clear
	notif "Entrer le numéro correspondant à votre choix"
	echo "~~~~~~~~MODE~~~~~~~~"
	echo "  [1] Mode solo"
	echo "  [2] Mode assistant"
	echo "  [3] Mode duel"
	echo "  [4] Retour"
	read mode

	while [ -z "$mode" ];do
	echo "Redéfinissez votre choix"
	read mode
	done

	while [ "$mode" != '1' -a "$mode" != '2' -a "$mode" != '3' -a "$mode" != '4' ];do
		echo "Redéfinissez votre choix"
		read mode
	done
	if [ "$mode" = "1" ]; then
		modules 
	elif [ "$mode" = "2" ]; then
		echo "Encore en cours. Be patient."
	elif [ "$mode" = "3" ]; then
		compiler_duel
		affiche_duel
	elif [ "$mode" = "4" ]; then
		return 
	fi
done
}

modules()
{
    while true; do
        clear
        notif "Entrer le numéro correspondant à votre choix"
        echo ""	
        echo "=====THEMES====="
        echo "~~~~~📁💬🔏~~~~~"
        echo ""
        echo "[1] Gestion de fichiers"
        echo "[2] Traitements de texte"
        echo "[3] Droits et permissions"
        echo "[4] Retour"
        echo "Entrez votre choix: "
        read module_choix

        while [ -z "$module_choix" ]; do
            echo "Redéfinissez votre choix"
            read module_choix
        done
        
        while [ "$module_choix" != '1' -a "$module_choix" != '2' -a "$module_choix" != '3' -a "$module_choix" != '4' ]; do
            echo "Redéfinissez votre choix"
            read module_choix
        done

        if [ "$module_choix" = '1' ]; then
            Theme_actuel="Gestion de fichiers"
            numero_theme=1
            niveau
        elif [ "$module_choix" = '2' ]; then
            Theme_actuel="Traitement de texte"
            numero_theme=2
            niveau
        elif [ "$module_choix" = '3' ]; then
            Theme_actuel="Droits et permissions"
            numero_theme=3
            niveau
        elif [ "$module_choix" = '4' ]; then
            return
        fi
    done
}

niveau()
{
    clear
    notif "Entrer le numéro correspondant à votre choix"
    echo "=======NIVEAU======="
    echo "Thème: $Theme_actuel"
    echo " "
    afficher_progress_niveau
    echo "[4] Retour"
    echo ""
    read op

    while [ -z "$op" ]; do
        echo "Redéfinissez votre choix"
        read op
    done

    while [ "$op" != '1' -a "$op" != '2' -a "$op" != '3' -a "$op" != '4' ]; do
        echo "Redéfinissez votre choix"
        read op 
    done
    
    if [ "$op" = '4' ]; then
        return
    fi

    #verifier na si le niveau est débloqué ou non
    local repere
    repere=$(theme_repere)
    local niv_choisi=""
    
    if   [ "$op" = '1' ]; then niv_choisi="niveau1"
    elif [ "$op" = '2' ]; then niv_choisi="niveau2"
    elif [ "$op" = '3' ]; then niv_choisi="niveau3"
    fi
    
    
    local score_actuel
    score_actuel=$(lire_score "$repere" "$niv_choisi")
    
    #Si verouillé alors refuser l'accès et expliquer
    if [ "$score_actuel" = "verrou" ]; then
    	echo " Ce niveau est verouillé 🔒 "
    	
    	if [ "$niv_choisi" = "niveau2" ]; then
	    local s1
            s1=$(lire_score "$repere" "niveau1")
            echo "   Terminez le niveau 1 avec au moins ${minimum}%"
            echo "   Votre meilleur score niveau 1 : ${s1}%"
    	elif [ "$niv_choisi" = "niveau3" ]; then
            local s2
            s2=$(lire_score "$repere" "niveau2")
            echo "   Terminez le niveau 2 avec au moins ${minimum}%"
            echo "   Votre meilleur score niveau 2 : ${s2}%"
        fi  
        
        sleep 3
        niveau #re afficher le meni niveau
        return
     fi
    
    	if [ "$op" = '1' ]; then
    	    echo "on va y aller doucement"
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau1"

    	elif [ "$op" = '2' ]; then
    	    echo "Tu peux le faire"
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau2"
        
    	elif [ "$op" = '3' ]; then
    	    echo "HAAH! on devient expert"
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau3"
        
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

resultat()
{
    local score_final=$1
    local total_questions=$2
    local niveau_affiche=$3    
    clear
    echo "==================="
    echo "   FIN DU NIVEAU   "
    echo "==================="
    echo ""
    echo "Thème : $Theme_actuel"
    echo "Niveau : $niveau_affiche"
    echo ""
    echo "Score final : $score_final / $total_questions"
    echo ""

    # Message selon performance
    local ratio=$((score_final * 100 / total_questions))
    if [ "$ratio" -ge 80 ]; then
        echo "Excellent ! Tu maîtrises ce niveau !"
    elif [ "$ratio" -ge "$minimum" ]; then
        echo "Pas mal ! Continue à t'entraîner, tu as atteint le seuil de déblocage du niveau suivant."
    else
        echo "Courage ! Réessaie pour t'améliorer, il faut ${minimum}% pour débloquer le niveau suivant!"
    fi
    
    local repere
    repere=$(theme_repere) #manova ny numero_theme ho nom du theme
    
    local ancien
    ancien=$(lire_score "$repere" "$niveau_affiche")
    
	if [ "$ancien" != "verrou" ] && [ "$ancien" -ge "$ratio" ] 2>/dev/null; then
        	echo ""
        	echo "Meilleur score conservé : ${ancien}% (actuel : ${ratio}%)"
	else
        	# Nouveau meilleur score => sauvegarder
        	sauver_score "$repere" "$niveau_affiche" "$ratio"
        	echo ""
        	echo "Nouveau meilleur score : ${ratio}%"
        fi
        
    #deblocage niveau suivant raha mahatratra ny seuil ou min=60%    
    debloque_niv "$repere" "$niveau_affiche" "$ratio"

    echo "$(date '+%d/%m/%Y %H:%M') | $prenom | $Theme_actuel | $niveau_affiche | $ratio" >> MasterLin/historique.txt
    
    echo ""
    echo "Appuyer sur Entrer pour revenir"
    read
}

accueil
menu_principal

