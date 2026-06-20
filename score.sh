#!/bin/bash

# ==========================================
# CONSTANTES DE STYLE (Couleurs Modernes)
# ==========================================
CLR_RESET="\033[0m"
CLR_BOLD="\033[1m"
CLR_DIM="\033[2m"

# Nouvelles nuances demandées
TXT_BLEU="\033[38;5;39m"     # Bleu électrique
TXT_VIOLET="\033[38;5;135m"  # Violet / Magenta brillant
TXT_JAUNE="\033[38;5;220m"   # Jaune vif
TXT_VERT="\033[38;5;82m"     # Vert néon (pour les succès)
TXT_ROUGE="\033[38;5;196m"    # Rouge vif (pour le verrouillé)
TXT_BLANC="\033[38;5;255m"

# Couleurs de fond
BG_VIOLET="\033[48;5;93m"
BG_VERT="\033[48;5;28m"

# ==========================================
# FONCTIONS
# ==========================================

resultat()
{
    local score_final=$1
    local total_questions=$2
    local niveau_affiche=$3    
    clear
    
    # En-tête double ligne aligné de façon fixe
    echo -e "${TXT_VIOLET}╔══════════════════════════════════════════════════════════╗${CLR_RESET}"
    echo -e "${TXT_VIOLET}║${CLR_RESET} ${BG_VIOLET}${TXT_BLANC}${CLR_BOLD}                    ★ FIN DU NIVEAU ★                   ${CLR_RESET} ${TXT_VIOLET}║${CLR_RESET}"
    echo -e "${TXT_VIOLET}╠══════════════════════════════════════════════════════════╣${CLR_RESET}"
    echo -e "${TXT_VIOLET}║${CLR_RESET}  ${TXT_BLEU}➔ Thème  :${CLR_RESET} ${CLR_BOLD}$Theme_actuel${TXT_VIOLET}                          ║${CLR_RESET}"
    echo -e "${TXT_VIOLET}║${CLR_RESET}  ${TXT_BLEU}➔ Niveau :${CLR_RESET} ${CLR_BOLD}$niveau_affiche${TXT_VIOLET}                                      ║${CLR_RESET}"
    echo -e "${TXT_VIOLET}╚══════════════════════════════════════════════════════════╝${CLR_RESET}"
    echo ""
    
    # Zone d'affichage du Score dynamique (Vert si >= 3, Rouge si < 3)
    local CLR_SCORE
    if [ "$score_final" -ge 3 ]; then
        CLR_SCORE="$TXT_VERT"
    else
        CLR_SCORE="$TXT_ROUGE"
    fi

    echo -e "  ${CLR_SCORE}┌────────────────────────────────────────┐${CLR_RESET}"
    echo -e "    ${CLR_BOLD}SCORE FINAL :${CLR_RESET} ${CLR_SCORE}${CLR_BOLD}$score_final${CLR_RESET} / ${TXT_BLANC}$total_questions${CLR_RESET}"
    echo -e "  ${CLR_SCORE}└────────────────────────────────────────┘${CLR_RESET}"
    echo ""

    # Message selon performance (Ta logique pure)
    local ratio=$((score_final * 100 / total_questions))
    echo -n "  "
    if [ "$ratio" -ge 80 ]; then
        echo -e "${TXT_VERT} Excellent ! Tu maîtrises ce niveau ! ${CLR_RESET}"
    elif [ "$ratio" -ge "$minimum" ]; then
        echo -e "${TXT_BLEU} Pas mal ! Continue à t'entraîner, tu as atteint le seuil de déblocage du niveau suivant. ${CLR_RESET}"
    else
        echo -e "${TXT_ROUGE} Courage ! Réessaie pour t'améliorer, il faut ${minimum}% pour débloquer le niveau suivant!${CLR_RESET}"
    fi
    
    local repere
    repere=$(theme_repere)
    
    local ancien
    ancien=$(lire_score "$repere" "$niveau_affiche")
    
    if [ "$ancien" != "verrou" ] && [ "$ancien" -ge "$ratio" ] 2>/dev/null; then
        echo ""
        echo -e "  ${CLR_DIM} Meilleur score conservé : ${ancien}% (actuel : ${ratio}%)${CLR_RESET}"
    else
        sauver_score "$repere" "$niveau_affiche" "$ratio"
        echo ""
        echo -e "   ${TXT_JAUNE}${CLR_BOLD}Nouveau meilleur score : ${ratio}%${CLR_RESET} "
    fi
        
    debloque_niv "$repere" "$niveau_affiche" "$ratio"

    echo "$(date '+%d/%m/%Y %H:%M') | $prenom | $Theme_actuel | $niveau_affiche | $ratio" >> MasterLin/historique.txt
    
    echo ""
    echo -e "  ${TXT_VIOLET}⎋${CLR_RESET} ${CLR_DIM}Appuyer sur Entrer pour revenir...${CLR_RESET}"
    read -r
}

fic()
{
    echo "MasterLin/progression_${prenom}.txt"
}

init_progression() 
{
    local fichier
    fichier=$(fic)

    if [ ! -f "$fichier" ]; then
        touch "$fichier"
        printf '%s\n' "gestion_niveau1=0" "gestion_niveau2=verrou" "gestion_niveau3=verrou" "texte_niveau1=0" "texte_niveau2=verrou" "texte_niveau3=verrou" "droits_niveau1=0" "droits_niveau2=verrou" "droits_niveau3=verrou" "processus_niveau1=0" "processus_niveau2=verrou" "processus_niveau3=verrou" > "$fichier"
        chmod 600 "$fichier"
    fi
}

lire_score() 
{
    local theme=$1    
    local niv=$2 
    local repere="${theme}_${niv}"
    local fichier
    fichier=$(fic)
    grep "^${repere}=" "$fichier" | cut -d'=' -f2
}

sauver_score() 
{
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
            echo -e "  ${BG_VERT}${TXT_BLANC}${CLR_BOLD}  NIVEAU DÉBLOQUÉ : $niv_suivant ! ${CLR_RESET}"
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

afficher_progress_niveau() 
{
local repere
repere=$(theme_repere)
local s1 s2 s3

s1=$(lire_score "$repere" "niveau1")
s2=$(lire_score "$repere" "niveau2")
s3=$(lire_score "$repere" "niveau3")

local L_CYAN='\033[96m'
local L_YELLOW='\033[93m'
local L_RED='\033[91m'
local L_BLUE='\033[94m'
local RESET='\033[0m'

local ligne1 ligne2 ligne3
    if [ "$s1" = "verrou" ]; then
    ligne1="${L_BLUE}🔒 Verrouillé${RESET}"
else
    ligne1="${L_BLUE}🔓 Meilleur score : ${s1}%      ${RESET}"
fi
if [ "$s2" = "verrou" ]; then
    ligne2="${L_YELLOW}🔒 Verrouillé (besoin ${minimum}% au niveau 1)${RESET}"
else
    ligne2="${L_YELLOW}🔓 Meilleur score : ${s2}%    ${RESET}"
fi

if [ "$s3" = "verrou" ]; then
    ligne3="${L_RED}🔒 Verrouillé (besoin ${minimum}% au niveau 2)${RESET}"
else
    ligne3="${L_RED}🔓 Meilleur score : ${s3}%      ${RESET}"
fi
    
echo -e "  ${L_CYAN}◈${RESET} ${L_BLUE}[1] Niveau 1${RESET}      ${ligne1}"
echo -e "  ${L_CYAN}◈${RESET} ${L_YELLOW}[2] Niveau 2${RESET}      ${ligne2}"
echo -e "  ${L_CYAN}◈${RESET} ${L_RED}[3] Niveau 3${RESET}      ${ligne3}"
}
