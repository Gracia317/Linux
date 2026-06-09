#!/bin/bash

reponse () {
    # Lire l'IP de l'expéditeur depuis le fichier tmp de PORT2 (port d'écoute de l'assistant)
    local ip_pc1
    ip_pc1=$(cut -d ':' -f2 "/tmp/msg_${PORT2}.tmp" 2>/dev/null)
    if [ -z "$ip_pc1" ]; then
        echo "Aucun message reçu"
        sleep 2
        return
    fi
    ecrire_msg "$ip_pc1" "$PORT2"
}

recevoir_msg () {
    local port=$1
    local sms="/tmp/msg_${port}.tmp"   # fichier unique par port
    touch "$sms"
    while true; do
        > "$sms" # videna aloha le fichier pour être sûr hoe tsisy erreur d'affichage 
        nc -l -p "$port" > "$sms"
        if [ -s "$sms" ]; then # raha misy le fichier
            local source msg
            source=$(cut -d ':' -f1 "$sms")
            msg=$(cut -d ':' -f3- "$sms")
            if [ -n "$msg" ] && [ -n "$source" ]; then
                zenity --title="Message de : $source" --info --text="$msg" --ok-label="Lu" 2>/dev/null
            fi
        fi
    done
}

ecrire_msg () {
    local ip=$1
    local port=$2
    local mon_ip
    mon_ip=$(hostname -I | awk '{print $1}')   # première IP seulement
    local name="$SUDO_USER" # "${SUDO_USER:-$USER}" pour éviter l'erreur de SUDO_USER vide si on veut
    local message
    echo "Entrer votre message :"
    read  message
    echo "tonga"
    echo "${name}:${mon_ip}:${message}" | nc -w 5 "$ip" "$port"
    echo "Message envoyé !"
}

barre_chargement() {
    echo -n "Chargement : ["
    for i in {1..25}; do
        echo -n "#"
        sleep 0.1
    done
    echo "] Terminé!"
}

notif() {
(
    local message=$1
    local couleur="\e[5;7m"
    local reset="\e[0m"
    echo -ne "\e[s\e[1;30H${couleur}$message${reset}\e[u"
    sleep 5
    local espaces
    espaces=$(printf "%${#message}s" "")
    echo -ne "\e[s\e[1;30H${espaces}\e[u"
) &
}

check_nmap () {
    local plage
    plage=$(ip route show | grep default | awk '{print $5}' | xargs ip route show dev | grep -v default | awk '{print $1}')
    if command -v nmap &>/dev/null; then
        echo "Les adresses IP des PC connectés disponibles sont :"
        local my_IP routeur_IP LIGNE NB_MOTS
        my_IP=$(hostname -I)
        routeur_IP=$(ip route show | grep default | awk '{print $3}')
        LIGNE=$(nmap -PR -sn "$plage" | grep "Nmap scan report for" | grep -v -e "$my_IP" -e "$routeur_IP")
        NB_MOTS=$(echo "$LIGNE" | wc -w)
        if [ "$NB_MOTS" -eq 5 ]; then
            local IP
            IP=$(echo "$LIGNE" | awk '{print $5}')
            echo "Inconnu $IP"
        elif [ "$NB_MOTS" -eq 6 ]; then
            local HOSTNAME IP
            HOSTNAME=$(echo "$LIGNE" | awk '{print $5}')
            IP=$(echo "$LIGNE" | awk '{print $6}' | tr -d '()')
            echo "$HOSTNAME $IP"
        fi
        if [ -z "$(nmap -PR -sn "$plage" | grep "Nmap scan report for" | awk '{print $NF}' | tr -d '()' | grep -v -e "$my_IP" -e "$routeur_IP")" ]; then
            echo "Vous êtes le seul PC connecté"
        fi
    else
        echo "nmap n'est pas installé. Lancement de l'installation..."
        installer "nmap"
        check_nmap
    fi
}

installer () {
    local os
    os=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$os" in
        ubuntu|debian) 
        apt-get update -y && apt-get install -y "$1" 
        ;;
        fedora)        
        dnf install -y "$1" 
        ;;
        arch)          
        pacman -Sy --noconfirm "$1" 
        ;;
        *) 
        echo "[-] Distribution non prise en charge ($os). Veuillez installer $1 manuellement." 
        ;;
    esac
}

installer_nc () {
    local os
    os=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$os" in
        ubuntu|debian) 
        apt-get update -y && apt-get install -y netcat-openbsd 
        ;;
        fedora)        
        dnf install -y nc 
        ;;
        arch)          
        pacman -Sy --noconfirm gnu-netcat 
        ;;
        *) 
        echo "[-] Distribution non prise en charge ($os). Installez Netcat manuellement." 
        ;;
    esac
}

check_nc () {
    if ! command -v nc &>/dev/null; then
        echo "Netcat (nc) n'est pas installé. Lancement de l'installation..."
        installer_nc
        check_nc
    fi
}
