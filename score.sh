#!/bin/bash
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

fic()
{
	echo "MasterLin/progression_${prenom}.txt" ;
}

#natao ity ho an'ny joueur vao nanomboka
#ny niveau 1 rehetra misokatra avec ratio 0 et les autres sont verrouillés
init_progression() 
{
    local fichier
    fichier=$(fic)

    # Ne créer que si le fichier n'existe pas encore
    #theme_niveau=ratio ---> Io no format repère an'ny progression
    if [ ! -f "$fichier" ]; then
    	touch "$fichier"
        printf '%s\n' "gestion_niveau1=0" "gestion_niveau2=verrou" "gestion_niveau3=verrou" "texte_niveau1=0" "texte_niveau2=verrou" "texte_niveau3=verrou" "droits_niveau1=0" "droits_niveau2=verrou" "droits_niveau3=verrou" "processus_niveau1=0" "processus_niveau2=verrou" "processus_niveau3=verrou" > "$fichier" # c'est plus sûr que EOF question bug satria mora misy bug le EOF de zay ny nahatonga anle tamry
        #%s ohatran am C ihany hoe manoratra chaîne de caract fa le \n eto midika fa isaky ny chaine de carct dia manao retour à la ligne.Donc mitovy amle version taloha ihany ny affichage mais avec moins de possibilité de bug
        # Protection : seul le propriétaire peut lire/écrire
        chmod 600 "$fichier"
    fi
}

lire_score() 
{
	#fampiasana an'io fonction io: lire_score "theme" "niveau" ary @ debloque_niv no ampiasana
	#mamaky anle ao aorian'ny '=' ao am fichier progression
	local theme=$1    
	local niv=$2 
	local repere="${theme}_${niv}"
	local fichier
	fichier=$(fic)
	#afin d'extraire le ratio après '='
	grep "^${repere}=" "$fichier" | cut -d'=' -f2 #| tr -d '\r' | sed 's/[[:space:]]*$//' pour éviter le anomalies décriture ex: \r invisible (pour windows) et les espaces invisibles par erreur de sasie   fa afaka tsy asina de nasiko an'ity commentaire ity le izy.
}

sauver_score() 
{
	#sauver_score "theme" "niveau" "ratio"
	#manova ny ratio ho ratio vaovao
	local theme=$1
	local niv=$2
	local ratio=$3
	local repere="${theme}_${niv}"
	local fichier
	fichier=$(fic)
	sed -i "s/^${repere}=.*/${repere}=${ratio}/g" "$fichier"
}

debloque_niv()
{
#debloque_niv "theme" "niv_actuel" "ratio"
local theme=$1
local niv_actuel=$2
local ratio=$3
local fichier
fichier=$(fic)
local niv_suivant=""
	if   [ "$niv_actuel" = "niveau1" ]; then niv_suivant="niveau2"
	elif [ "$niv_actuel" = "niveau2" ]; then niv_suivant="niveau3"
	fi
	
	if [ -n "$niv_suivant" ] && [ "$ratio" -ge "$minimum" ]; then
        	local repere_suivant="${theme}_${niv_suivant}"
        	local score_suivant
        	score_suivant=$(lire_score "$theme" "$niv_suivant")
        
        	if [ "$score_suivant" = "verrou" ]; then
            		sed -i "s/^${repere_suivant}=verrou/${repere_suivant}=0/" "$fichier"
            		echo ""
            		echo "🔓 Niveau débloqué : $niv_suivant !"
            		sleep 2
            	fi
        fi
}

theme_repere() 
{
if   [ "$numero_theme" = "1" ]; then echo "gestion"
elif [ "$numero_theme" = "2" ]; then echo "texte"
elif [ "$numero_theme" = "3" ]; then echo "droits"
elif [ "$numero_theme" = "4" ]; then echo "processus"
fi
}

# Afficher la progression d'un thème dans le menu niveau (voir menu niveau pour plus de comprehension)
afficher_progress_niveau() 
{
local repere
repere=$(theme_repere)
local s1 s2 s3

s1=$(lire_score "$repere" "niveau1")
s2=$(lire_score "$repere" "niveau2")
s3=$(lire_score "$repere" "niveau3")

local affiche1 affiche2 affiche3

    if [ "$s1" = "verrou" ]; then affiche1="🔒 Verrouillé"
    else affiche1="🔓 Meilleur score : ${s1}%"
    fi

    if [ "$s2" = "verrou" ]; then affiche2="🔒 Verrouillé (besoin ${minimum}% au niveau 1)"
    else affiche2="🔓 Meilleur score : ${s2}%"
    fi

    if [ "$s3" = "verrou" ]; then affiche3="🔒 Verrouillé (besoin ${minimum}% au niveau 2)"
    else affiche3="🔓 Meilleur score : ${s3}%"
    fi

    echo "[1] Niveau 1  —  $affiche1"
    echo "[2] Niveau 2  —  $affiche2"
    echo "[3] Niveau 3  —  $affiche3"
}
