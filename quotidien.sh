#!/bin/bash

defi()
{
# Configuration des chemins d'accès
CSV_DEFIS="./questions/defis.csv"
FICHIER_SUIVI="/var/log/masterlin/suivis_defis.txt"

DATE_AUJOURDHUI=$(date +%Y-%m-%d)

# 1. VERROUILLAGE : L'utilisateur a-t-il déjà réussi aujourd'hui ?
if grep -q "^${USER}:${DATE_AUJOURDHUI}:REUSSI" "$FICHIER_SUIVI" 2>/dev/null; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Défi du jour déjà validé avec succès !"
    echo " Revenez demain pour 3 nouveaux défis."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    chmod 400 "$FICHIER_SUIVI"
    chmod 600 /var/log/masterlin/defi.log
    echo "$USER a tenté de rejouer le défi du jour déjà validé." > /var/log/masterlin/defi.log
    chmod 400 /var/log/masterlin/defi.log
    sleep 3
    return 0
    sleep 3
    exit 0
fi

clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "         BIENVENUE DANS LES DÉFIS PRATIQUES DU JOUR "
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Vous devez réussir 3 défis système d'affilée."
echo "En cas d'échec, vous pourrez réessayer autant que vous voulez."
echo "------------------------------------------------------------"
sleep 4
clear

mapfile -t LIGNES_CHOISIES < <(awk -F';' -v d="$DATE_AUJOURDHUI" '{print $0}' "$CSV_DEFIS" | shuf | head -n 3)

DEFIS_REUSSIS=0

# 3. BOUCLE D'EXECUTION DES 3 DEFIS
for i in {0..2}; do
    # Extraction des données du CSV via IFS
    IFS=';' read -r id categorie consigne prep tesita clean <<< "${LIGNES_CHOISIES[$i]}"
    
    echo -e "\n [Défi $((i+1))/3] Catégorie : \e[1;34m$categorie\e[0m"
    echo -e " \e[1mConsigne :\e[0m $consigne"
    
    # Exécution discrète de la commande de préparation
    eval "$prep" 2>/dev/null
    
    # Attente de l'action de l'utilisateur
    echo -e "Réalisez l'action dans un autre terminal, puis appuyez sur [ENTRÉE] pour valider ${BOLD}(Sans action vous quittez directement)${RESET}..."
    read 
    
    # Évaluation de la condition de réussite
    if eval "$tesita" 2>/dev/null; then
        echo -e "\e[1;32m Excellent ! Défi validé.\e[0m"
        sleep 3
        echo -e "${BOLD}Suivant ...${RESET}"
        DEFIS_REUSSIS=$((DEFIS_REUSSIS + 1))
        echo "Défi ID $id ($categorie) RÉUSSI par $USER" >> /var/log/masterlin/defi.log
        chmod 400 /var/log/masterlin/defi.log
    else
        echo -e "\e[1;31m Échec. La configuration attendue n'est pas correcte. Réessayez plutard\e[0m"
        sleep 4
        chmod 600 /var/log/masterlin/defi.log
        echo "Défi ID $id ($categorie) ÉCHOUÉ par $USER" >> /var/log/masterlin/defi.log
        chmod 400 /var/log/masterlin/defi.log
        
        # Nettoyage immédiat
        eval "$clean" 2>/dev/null
        break
    fi
    
    # Nettoyage systématique après réussite pour ne pas polluer /tmp
    eval "$clean" 2>/dev/null
done

# 4. BILAN DE LA SÉRIE
echo -e "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $DEFIS_REUSSIS -eq 3 ]; then
    echo -e " \e[1;32mVICTOIRE ! Vous avez surmonté les épreuves du jour! \e[0m"
    echo " Votre exploit est enregistré. Rendez-vous demain !"
    
    # Écriture dans le fichier de suivi pour bloquer les futures tentatives aujourd'hui
    mkdir -p "$(dirname "$FICHIER_SUIVI")"
    echo "${USER}:${DATE_AUJOURDHUI}:REUSSI" >> "$FICHIER_SUIVI"
    chmod 600 /var/log/masterlin/defi.log
    echo "Série 'Défi du jour' ENTIÈREMENT COMPLÉTÉE par $USER" >> /var/log/masterlin/defi.log
    chmod 400 /var/log/masterlin/defi.log
else
    echo -e " \e[1;31mSérie échouée ($DEFIS_REUSSIS/3 défis réussis).\e[0m"
    echo " Prenez le temps de réviser vos commandes et relancez l'option !"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
clear
return 0
}
