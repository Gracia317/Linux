#!/bin/bash

recevoir_msg () {
    local port=$1
    sms="/tmp/msg_${port}.tmp" # fichier unique par port
    ip="/tmp/ip_${port}.tmp"
    touch "$sms" "$ip"
    while true; do
        nc -l -p "$port" > "$sms"
    if [ -s "$sms" ]; then # raha misy le fichier
            local source msg ip_dest
            ip_dest=$(cut -d ':' -f2 "$sms")
            echo "$ip_dest" > "$ip"
            source=$(cut -d ':' -f1 "$sms")
            msg=$(cut -d ':' -f3- "$sms")
      if [ -n "$msg" ] && [ -n "$source" ]; then
      paplay /usr/share/sounds/freedesktop/stereo/complete.oga
         reponse_texte=$(zenity --entry --title="Message de : $source" --text="$msg\n\nVotre réponse :" --ok-label="Envoyer" --cancel-label="Ignorer" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$reponse_texte" ]; then
        local mon_ip mon_nom port_dest
        mon_ip=$(hostname -I | awk '{print $1}')
        mon_nom="$USER"

        if [ "$port" = "$PORT1" ]; then
            port_dest="$PORT2"
        else
            port_dest="$PORT1"
        fi

        echo "${mon_nom}:${mon_ip}:${reponse_texte}" | nc -w 5 "$ip_dest" "$port_dest"
       fi
       fi
    fi 
    done
}

ecrire_msg () {
    local ip=$1
    local port=$2
    local mon_ip
    mon_ip=$(hostname -I | awk '{print $1}')   # première IP seulement
    local name="$USER"
    local message
    echo "Entrer votre message :"
    read  message </dev/tty
    echo "${name}:${mon_ip}:${message}" | nc -w 5 "$ip" "$port"
    echo "Message envoyé !"
}

barre_chargement() {
local largeur=25
local vert="\e[1;32m"
local jaune="\e[1;33m"
local reset="\e[0m"
local rempli=""

echo -ne "${jaune}Chargement : ${reset}["
    for ((i=1; i<=largeur; i++)); do
        rempli+="#"
        local pourcentage=$((i * 100 / largeur))
        # \r remet le curseur au début de la ligne
        printf "\r${jaune}Chargement : ${reset}[${vert}%-${largeur}s${reset}] %3d%%" "$rempli" "$pourcentage"
        sleep 0.1
    done
    echo -e "  ${vert}Terminé! ${reset}"
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

installer () {
    local os
    os=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$os" in
        ubuntu|debian) 
        sudo apt-get update -y && sudo apt-get install -y "$1" 
        ;;
        fedora)        
        sudo dnf install -y "$1" 
        ;;
        arch)          
        sudo pacman -Sy --noconfirm "$1" 
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
        sudo apt-get update -y && sudo apt-get install -y netcat-openbsd 
        ;;
        fedora)        
        sudo dnf install -y nc 
        ;;
        arch)          
        sudo pacman -Sy --noconfirm gnu-netcat 
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
 
installer_audio () {
    local os
    os=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$os" in
        ubuntu|debian) 
        sudo apt-get update -y && sudo apt-get install -y pulseaudio-utils 
        ;;
        fedora)        
        sudo dnf install -y  pulseaudio-utils 
        ;;
        arch)          
        sudo pacman -Sy --noconfirm libpulse
        ;;
        *) 
        echo "[-] Distribution non prise en charge ($os). Veuillez installer pulseaudio-utils  manuellement." 
        ;;
    esac
}

check_audio () {
    if ! command -v paplay &>/dev/null; then
        echo "Pulseaudio-utils n'est pas installé, connexion internet requise. Lancement de l'installation..."
        installer_audio
        check_audio
    fi
}
