#!/bin/bash
source ./assist.sh
source ./duel.sh
source ./score.sh

RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"
MAGENTA="\033[35m"
GREEN="\033[32m"
YELLOW="\033[33m"
PURPLE='\033[38;5;135m'
CORAL='\033[38;5;209m'
GRAY='\033[38;5;245m'
WHITE='\033[38;5;255m'

Mode () {

local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local PURPLE='\033[38;5;135m'
local GREEN='\033[38;5;78m'
local CORAL='\033[38;5;209m'
local GRAY='\033[38;5;245m'
local WHITE='\033[38;5;255m'
local CYAN='\033[36m'

clear
while true; do
    clear
    echo ""
    echo -e " ${CORAL}◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    echo -e "  ${PURPLE}◆  SÉLECTION DU MODE DE JEU${RESET}"
    echo -e "  ${DIM}${CYAN}A vous de choisir le Mode de jeu${RESET}"
    echo ""

    echo -e "  ${PURPLE}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "    ${BOLD}${WHITE}[1]${RESET}    ${PURPLE}Mode solo${RESET}      ${DIM}${GRAY}— S'entraîner seul ${RESET}"
    echo -e "  ${PURPLE}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${GREEN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "    ${BOLD}${WHITE}[2]${RESET}    ${GREEN}Mode assistant${RESET} ${DIM}${GRAY}— Obtenir un support ${RESET}"
    echo -e "  ${GREEN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${CORAL}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "    ${BOLD}${WHITE}[3]${RESET}    ${CORAL}Mode duel${RESET}      ${DIM}${GRAY}— Affronter un autre joueur ${RESET}"
    echo -e "  ${CORAL}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${GRAY}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "    ${BOLD}${WHITE}[4]${RESET}    ${GRAY}Retour menu${RESET}    ${DIM}${GRAY}— Revenir au tableau de bord principal${RESET}"
    echo -e "  ${GRAY}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e " ${CORAL}◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
    
    echo -e -n "  ${PURPLE} Votre choix ❯${RESET} "
    read choix_mode

    if [ "$choix_mode" = '1' ]; then
        clear
        modules
        break
    elif [ "$choix_mode" = '2' ]; then
        clear
        modules_as
        break
    elif [ "$choix_mode" = '3' ]; then
        clear
        affiche_duel
        break
    elif [ "$choix_mode" = '4' ]; then
        return 0
    else

        echo -e "  \033[91m Option invalide. Veuillez choisir entre 1 et 4.\033[0m"
        sleep 1.2
    fi
done
}

modules()
{
    while true; do
        clear
        echo ""
        echo -e "  ${PURPLE}◆  SÉLECTION DU THÈME${RESET}"
        echo ""
        echo -e "  ${DIM}${CYAN}Choisissez une catégorie pour vous entraîner${RESET}"
        echo ""

        echo -e "  ${PURPLE}╔═══════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${WHITE}[1]${RESET}    ${PURPLE}Gestion de fichiers${RESET}   ${DIM}${GRAY}— Dossiers, déplacements, liens...${RESET}"
        echo -e "  ${PURPLE}╚═══════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "  ${GREEN}╔═══════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${WHITE}[2]${RESET}    ${GREEN}Traitement de texte${RESET}   ${DIM}${GRAY}— Grep, sed, awk, redirections...${RESET}"
        echo -e "  ${GREEN}╚═══════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "  ${CORAL}╔═══════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${WHITE}[3]${RESET}    ${CORAL}Droits & Permissions${RESET} ${DIM}${GRAY}— Chmod, chown, identités...${RESET}"
        echo -e "  ${CORAL}╚═══════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "  ${YELLOW}╔═══════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${WHITE}[4]${RESET}    ${YELLOW}Gestion des Processus${RESET} ${DIM}${GRAY}— Ps, kill, background jobs...${RESET}"
        echo -e "  ${YELLOW}╚═══════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e "  ${GRAY}╔═══════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${WHITE}[5]${RESET}    ${GRAY}Retour menu${RESET}           ${DIM}${GRAY}— Revenir au choix du mode${RESET}"
        echo -e "  ${GRAY}╚═══════════════════════════════════════════════════════════════╝${RESET}"
        echo ""
        echo -e " ${CORAL}◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤${RESET}"
        
        echo -e -n "  ${PURPLE} Votre choix ❯${RESET} "
        notif "Entrer le numéro correspondant à votre choix"
       
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
local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local L_YELLOW='\033[93m'   
local L_RED='\033[91m'      
local L_BLUE='\033[94m'  
local L_CYAN='\033[96m'

while true; do
    clear
    echo ""
    echo -e " ${L_CYAN}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
    echo -e "  ${L_YELLOW} CHOOSE YOUR DIFFICULTY${RESET}"
    echo -e "  ${L_BLUE}Secteur :${RESET} ${BOLD}${L_YELLOW}$Theme_actuel${RESET}"
    echo ""

    afficher_progress_niveau
    echo -e "\n"
    echo ""
    
    echo -e "  ${L_BLUE}▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰${RESET}"
    echo -e "  ${L_YELLOW} [4] RETOUR AUX THÈMES SYSTEME${RESET}"
    echo -e " ${L_CYAN}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
    echo ""
    
    echo -e -n "  ${L_CYAN}SELECT ❯${RESET} "
    read op

    while [ -z "$op" ]; do
        echo "Redéfinissez votre choix"
        read op
    done

    while [ "$op" != '1' -a "$op" != '2' -a "$op" != '3' -a "$op" != '4' ]; do
    	echo -e "  \033[91m[!] Erreur d'option. Choisissez de 1 à 4.\033[0m"
        read op 
    done
    
    if [ "$op" = '4' ]; then
        return
    fi

    local repere
    repere=$(theme_repere)
    local niv_choisi=""
    
    if   [ "$op" = '1' ]; then niv_choisi="niveau1"
    elif [ "$op" = '2' ]; then niv_choisi="niveau2"
    elif [ "$op" = '3' ]; then niv_choisi="niveau3"
    fi
    
    
    local score_actuel
    score_actuel=$(lire_score "$repere" "$niv_choisi")
    
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
        niveau 
        return
     fi
    
    	if [ "$op" = '1' ]; then
    	    echo ""
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau1"

    	elif [ "$op" = '2' ]; then
    	    echo ""
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau2"
        
    	elif [ "$op" = '3' ]; then
    	    echo ""
    	    barre_chargement
    	    sleep 2
    	    quizz "niveau3"
   	fi
done
}

modules_as()
{
local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local L_YELLOW='\033[93m'
local L_RED='\033[91m'
local L_BLUE='\033[94m'
local L_CYAN='\033[96m'

    while true; do
        clear
        echo ""
        echo -e " ${L_CYAN}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
        echo -e "  ${L_YELLOW} CHOOSE YOUR THEME (ASSISTANT)${RESET}"
        echo ""

        echo -e "  ${L_CYAN}◈${RESET} ${BOLD}${L_YELLOW}[1]${RESET} ${L_BLUE} Gestion de fichiers${RESET}"
        echo -e "  ${L_CYAN}◈${RESET} ${BOLD}${L_YELLOW}[2]${RESET} ${L_YELLOW} Traitement de texte${RESET}"
        echo -e "  ${L_CYAN}◈${RESET} ${BOLD}${L_YELLOW}[3]${RESET} ${L_RED} Droits et permissions${RESET}"
        echo -e "  ${L_CYAN}◈${RESET} ${BOLD}${L_YELLOW}[4]${RESET} ${L_BLUE} Processus${RESET}"
        echo ""
        echo -e "  ${L_YELLOW}  [5] RETOUR AU CHOIX DU MODE${RESET}"
        echo -e " ${L_CYAN}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
        echo ""

        echo -e -n "  ${L_CYAN}SELECT ❯${RESET} "
        read module_choix
        notif "Entrer le numéro correspondant à votre choix"

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
local RESET='\033[0m'
local BOLD='\033[1m'
local DIM='\033[2m'
local L_YELLOW='\033[93m'
local L_RED='\033[91m'
local L_BLUE='\033[94m'
local L_CYAN='\033[96m'
local L_MAGENTA='\033[95m'
local WHITE='\033[97m'
local L_GREEN='\033[92m'

while true; do
    clear
    echo ""
    echo -e " ${L_MAGENTA}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
    echo -e "  ${L_CYAN} CHOOSE YOUR DIFFICULTY (ASSISTANT)${RESET}"
    echo -e "  ${DIM}${WHITE}Secteur :${RESET} ${BOLD}${L_YELLOW}$Theme_actuel${RESET}"
    echo ""

    afficher_progress_niveau
    echo -e "\n"
    echo ""

    echo -e "  ${L_CYAN}▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰${RESET}"
    echo -e "  ${WHITE} [4] RETOUR AUX THÈMES SYSTEME${RESET}"
    echo -e " ${L_MAGENTA}▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼▲▼${RESET}"
    echo ""

    echo -e -n "  ${L_MAGENTA}SELECT ❯${RESET} "
    read op

    while [ -z "$op" ]; do
        echo "Redéfinissez votre choix"
        read op
    done

    while [ "$op" != '1' -a "$op" != '2' -a "$op" != '3' -a "$op" != '4' ]; do
        echo -e "  \033[91m Choix invalide. Entrez un nombre de 1 à 4.\033[0m"
        read op
    done

    if [ "$op" = '4' ]; then
        return
    fi

    local repere
    repere=$(theme_repere)
    local niv_choisi=""

    if   [ "$op" = '1' ]; then niv_choisi="niveau1"
    elif [ "$op" = '2' ]; then niv_choisi="niveau2"
    elif [ "$op" = '3' ]; then niv_choisi="niveau3"
    fi

    local score_actuel
    score_actuel=$(lire_score "$repere" "$niv_choisi")

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
        continue
    fi

    if [ "$op" = '1' ]; then
        echo ""
        barre_chargement
        quizz_as "niveau1"
    elif [ "$op" = '2' ]; then
        echo ""
        barre_chargement
        quizz_as "niveau2"
    elif [ "$op" = '3' ]; then
        echo ""
        barre_chargement
        quizz_as "niveau3"
    fi
done
}
