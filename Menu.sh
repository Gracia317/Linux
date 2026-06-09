#!/bin/bash
source ./assist.sh
source ./duel1.sh
Mode () {
while true; do
  clear
  notif "Entrer le numéro correspondant à votre choix"
  echo "~~~~~~~~MODE~~~~~~~~"
  echo "  [1] Mode solo"
  echo "  [2] Mode assistant"
  echo "  [3] Mode duel"
  echo "  [4] Retour"
  read mode < /dev/tty
 
  if [ "$mode" = '1' ]; then
     modules
  elif [ "$mode" = '2' ]; then
     assist
    if [ -n "$pid_msg2" ]; then
     kill "$pid_msg2" 2>/dev/null
     wait "$pid_msg2" 2>/dev/null
    fi
    recevoir_msg "$PORT1" &
    pid_msg=$!
  elif [ "$mode" = '3' ]; then
     compiler_duel
     affiche_duel
  elif [ "$mode" = '4' ]; then
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
        echo "[4] Processus"
        echo "[5] Retour"
        echo "Entrez votre choix: "
        read module_choix

        while [ -z "$module_choix" ]; do
            echo "Redéfinissez votre choix"
            read module_choix
        done
        
        while [ "$module_choix" != '1' -a "$module_choix" != '2' -a "$module_choix" != '3' -a "$module_choix" != '4' -a "$module_choix" != '5' ]; do
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
            Theme_actuel="Processus"
            numero_theme=4
            niveau
        elif [ "$module_choix" = '5' ]; then
            return
        fi
    done
}

niveau()
{
while true; do
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
            echo "   Votre meilleur score niveau 2 : ${s2}%"s
	fi
        
        sleep 3
        niveau #re afficher le menu niveau
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
done
}

modules_as()
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
        echo "[4] Processus"
        echo "[5] Retour"
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
            niveau_as
        elif [ "$module_choix" = '2' ]; then
            Theme_actuel="Traitement de texte"
            numero_theme=2
            niveau_as
        elif [ "$module_choix" = '3' ]; then
            Theme_actuel="Droits et permissions"
            numero_theme=3
            niveau_as
        elif [ "$module_choix" = '4' ]; then
            Theme_actuel="Processus"
            numero_theme=4
            niveau_as
        elif [ "$module_choix" = '5' ]; then
            return
        fi
    done
}

niveau_as()
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
        niveau_as #re afficher le meni niveau
        return
     fi
    
    	if [ "$op" = '1' ]; then
    	    echo "on va y aller doucement"
    	    barre_chargement
    	    quizz_as "niveau1"

    	elif [ "$op" = '2' ]; then
    	    echo "Tu peux le faire"
    	    barre_chargement
    	    quizz_as "niveau2"
        
    	elif [ "$op" = '3' ]; then
    	    echo "HAAH! on devient expert"
    	    barre_chargement
    	    quizz_as "niveau3"
        
   	fi
}
