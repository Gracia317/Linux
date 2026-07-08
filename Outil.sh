#!/bin/bash
# =================================================================
# 1. VERIFICATION ET CONFIGURATION AUTOMATIQUE SILENCIEUSE
# =================================================================
verifier_et_installer_config() {
    local config_dir="/etc/masterlin"
    local config_file="$config_dir/masterlin.conf"
    
    # Si le fichier existe déjà, on ne fait rien et on quitte proprement
    if [ -f "$config_file" ]; then
        return 0
    fi

    clear
    echo -e "\n\033[93m[CONFIGURATION] Fichier de configuration manquant.\033[0m"
    echo -e "\033[97mCréation du fichier système : $config_file\033[0m"
    echo -e "\033[36m(Votre mot de passe 'sudo' est requis une seule fois pour configurer les permissions)\033[0m\n"

    # 1. Création du dossier et du fichier avec les privilèges root
    if sudo mkdir -p "$config_dir" && sudo touch "$config_file"; then
        
        # 2. Remplissage du fichier (ATTENTION : EOF doit être collé au début de la ligne !)
cat << 'EOF' | sudo tee "$config_file" > /dev/null
PORT_DUEL=9000
PORT1=6855
PORT2=5586
PORT3=7000
EOF

        # Donner les droits de lecture et d'écriture à tout le monde
        sudo chmod 666 "$config_file"
        sudo chmod 755 "$config_dir"

        echo -e "\033[92m[SUCCÈS] Le fichier de configuration a été installé avec succès !\033[0m"
        echo -e "\033[97mPermissions configurées : Tout utilisateur peut maintenant modifier ce fichier.\033[0m"
        sleep 2
    else
        echo -e "\033[91m[ERREUR] Échec de la configuration.\033[0m"
        sleep 2
    fi
}

# =================================================================
# 2. CHARGEMENT DYNAMIQUE ET VERIFICATION DES PORTS
# =================================================================
charger_et_verifier_ports() {
    # L'installation automatique ne se déclenche qu'ici (Mode Duel ou Assistant)
    verifier_et_installer_config

    local config_file="/etc/masterlin/masterlin.conf"
    
    if [ ! -f "$config_file" ]; then
        echo -e "\n\033[91m[ERREUR] Le fichier $config_file est introuvable !\033[0m"
        read -rp "Appuyez sur ENTREE pour revenir..."
        return 1
    fi

    # Extraction des valeurs du fichier .conf
    PORT_DUEL=$(grep -E '^PORT_DUEL=' "$config_file" | cut -d= -f2 | tr -d '[:space:]')
    PORT1=$(grep -E '^PORT1=' "$config_file" | cut -d= -f2 | tr -d '[:space:]')
    PORT2=$(grep -E '^PORT2=' "$config_file" | cut -d= -f2 | tr -d '[:space:]')
    PORT3=$(grep -E '^PORT3=' "$config_file" | cut -d= -f2 | tr -d '[:space:]')

    local liste_ports=("$PORT_DUEL" "$PORT1" "$PORT2" "$PORT3")
    local noms_ports=("PORT_DUEL" "PORT1" "PORT2" "PORT3")

    # Vérification : est-ce que ce sont bien des nombres ? (Pas de lettres)
    for i in "${!liste_ports[@]}"; do
        local p="${liste_ports[$i]}"
        local nom="${noms_ports[$i]}"
        
        if [[ ! "$p" =~ ^[0-9]+$ ]]; then
            echo -e "\n\033[91m[ERREUR] La valeur pour '$nom' ($p) n'est pas un nombre valide !\033[0m"
            echo -e "\033[33mVeuillez corriger le fichier $config_file (lettres interdites).\033[0m"
            read -rp "Appuyez sur ENTREE pour revenir au menu..."
            return 1
        fi
    done

    # Exporter les variables pour qu'elles soient visibles partout
    export PORT_DUEL PORT1 PORT2 PORT3
    return 0
}

barre_chargement () {
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

notif () {
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


# Verrou global pour sérialiser l'affichage des popups (un seul à la fois,
# même si un message arrive sur PORT1 et un autre sur PORT2 en même temps)
POPUP_LOCK="/tmp/masterlin_popup.lock"

# arreter_ecoute : libère un port de façon fiable.
# IMPORTANT : on tue par PORT (fuser) et pas par PID de la fonction bash,
# car "kill $pid_msgX" ne tue que le sous-shell qui attend nc, pas nc
# lui-même : nc devient orphelin et reste bindé sur le port -> conflits
# de port en re-rentrant en mode assistant. fuser cible directement le
# process qui tient le port, orphelin ou pas, et ne fait rien si le port
# est déjà libre (donc sans risque à appeler "au cas où").
arreter_ecoute () {
    local port=$1
    fuser -k -TERM "${port}/tcp" 2>/dev/null 1>&2
    sleep 0.2
    fuser -k -KILL "${port}/tcp" 2>/dev/null 1>&2
}

# demarrer_ecoute : libère le port puis relance recevoir_msg dessus,
# et renvoie le PID du job en arrière-plan (à stocker dans pid_msgX).
demarrer_ecoute () {
    local port=$1
    arreter_ecoute "$port"
    recevoir_msg "$port" > /dev/null 2>&1 &
    echo $!
}

recevoir_msg () {
    local port=$1
    local ip="/tmp/ip_${port}.tmp"
    touch "$ip"

    while true; do
        # Fichier unique par message (mktemp) et non plus un fichier fixe par port :
        # ça évite qu'un 2e message écrase le fichier du 1er pendant que celui-ci
        # est encore en cours de traitement (popup affiché en tâche de fond).
        local sms
        sms=$(mktemp "/tmp/msg_${port}_XXXXXX")
        nc -l -p "$port" > "$sms"

        if [ -s "$sms" ]; then # raha misy le fichier
            # Le traitement (son, popup, réponse) part en tâche de fond :
            # la boucle repart IMMÉDIATEMENT sur nc -l -p "$port", donc le port
            # est ré-armé sans attendre que l'utilisateur ait répondu au popup.
            # Avant : le port n'écoutait plus tant que zenity/tmux attendait une
            # saisie -> tout message envoyé pendant ce laps de temps était perdu
            # (connexion refusée côté expéditeur).
            traiter_message "$sms" "$ip" "$port" &
        else
            rm -f "$sms"
        fi
    done
}

# traiter_message : extrait, affiche (popup) et répond à UN message reçu.
# Isolée dans sa propre fonction + lancée en arrière-plan par recevoir_msg
# pour ne jamais bloquer l'écoute réseau.
traiter_message () {
    local Style_popup="bg=colour17,fg=white"
    local sms=$1
    local ip=$2
    local port=$3
    local source msg ip_dest

    ip_dest=$(cut -d ':' -f2 "$sms")
    echo "$ip_dest" > "$ip"
    source=$(cut -d ':' -f1 "$sms")
    msg=$(cut -d ':' -f3- "$sms")
    rm -f "$sms"

    if [ -n "$msg" ] && [ -n "$source" ]; then
        # statut/reponse_texte sont déclarées locales à CHAQUE message :
        # avant, si ni zenity ni tmux n'étaient disponibles pour un message
        # donné, ces variables gardaient la valeur du message précédent et
        # pouvaient renvoyer une ancienne réponse au mauvais moment.
        local statut=1
        local reponse_texte=""

        paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null

        # flock : un seul popup affiché à la fois pour tout le programme,
        # même si plusieurs messages arrivent en rafale sur PORT1 et PORT2.
        # Les autres messages restent simplement en file d'attente (chacun
        # dans son propre "traiter_message &") et s'afficheront l'un après
        # l'autre au lieu de se marcher dessus sur le terminal.
        (
        flock -x 200

        interface=$(echo $DISPLAY)
        if [ ! -z "$interface" ]; then
            #CAS INTERFACE GRAPHIQUE
            reponse_texte=$(zenity --entry --title="Message de : $source" --text="$msg\n\nVotre réponse :" --ok-label="Envoyer" --cancel-label="Ignorer" 2>/dev/null)
            statut=$?

        else
            # CAS CLI : VÉRIFICATION SI ON EST SOUS TMUX
            if [ -n "$TMUX" ]; then
                # Crée un fichier temporaire pour récupérer la réponse du popup
                local reponse_tmp="/tmp/reponse_popup_${port}.tmp"
                > "$reponse_tmp"

                # On lance un popup interactif tmux autonome
                # -E ferme automatiquement le popup à la fin de l'exécution
                local client_cible
                client_cible=$(tmux list-clients -t "$TMUX_PANE" -F '#{client_name}' 2>/dev/null | head -n1)

                if [ -z "$client_cible" ]; then
                    notif " >>> Impossible d'afficher le popup (aucun client tmux attaché) <<< "
                else
                    tmux display-popup -E -w 70 -h 12 -b rounded -s "$Style_popup" -c "$client_cible" -t "$TMUX_PANE" \
                        /bin/bash -c "       
                        RESET=\"\033[0m\"
                        WHITE_BRIGHT=\"\033[97m\"
                        QUIZ_BLUE=\"\033[38;5;27m\"
                        GREEN=\"\033[32m\"
                        clear
                        echo -e \"  ${QUIZ_BLUE}╔════════════════════════════════════════════════════════════╗${RESET}\"
                        echo -e \"       ${WHITE_BRIGHT} NOUVEAU MESSAGE DE : ${RESET} $source\"
                        echo -e \"  ${QUIZ_BLUE}╚════════════════════════════════════════════════════════════╝${RESET}\"
                        echo -e \"  ${WHITE_BRIGHT}[Contenu] :${RESET} $msg\"
                        echo -e \"  ${QUIZ_BLUE}────────────────────────────────────────────────────────────${RESET}\"
                        echo ""
                        echo -e -n \"  ${GREEN}❯ Votre réponse (Laissez vide pour ignorer) : ${RESET}\"
                        read resp
                        if [ -n \"\$resp\" ]; then
                            echo \"\$resp\" > \"$reponse_tmp\"
                        fi
                    "
                    # Lecture de la réponse générée dans le popup
                    if [ -s "$reponse_tmp" ]; then
                        reponse_texte=$(cat "$reponse_tmp")
                        statut=0
                        rm -f "$reponse_tmp"
                    else
                        statut=1
                        rm -f "$reponse_tmp"
                    fi
                fi
            fi
        fi

        if [ "$statut" -eq 0 ] && [ -n "$reponse_texte" ]; then
            local mon_ip mon_nom port_dest
            mon_ip=$(hostname -I | awk '{print $1}')
            mon_nom="$USER"
            if [ "$port" = "$PORT1" ]; then
                port_dest="$PORT2"
            else
                port_dest="$PORT1"
            fi
            if echo "${mon_nom}:${mon_ip}:${reponse_texte}" | nc -w 5 "$ip_dest" "$port_dest"; then
                sleep 1
            else
                notif " >>> Échec de l'envoi de la réponse à $source <<< "
            fi
        fi
        ) 200>"$POPUP_LOCK"
    fi
}

ecrire_msg () {
    local ip=$1
    local port=$2
    local mon_ip
    mon_ip=$(hostname -I | awk '{print $1}')   # première IP seulement
    local name="$USER"
    local message
    echo "==> Entrer votre message :"
    read  message </dev/tty
    if echo "${name}:${mon_ip}:${message}" | nc -w 5 "$ip" "$port"; then
        echo "==> Message envoyé !"
    else
        echo "==> Échec de l'envoi (destinataire injoignable ou port fermé)."
    fi
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

installer_tmux () {
    local os
    os=$(grep -E "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    case "$os" in
        ubuntu|debian) 
        sudo apt-get update -y && sudo apt-get install -y tmux
        ;;
        fedora)        
        sudo dnf install -y tmux
        ;;
        arch)          
        sudo pacman -Sy --noconfirm tmux
        ;;
        *) 
        echo "[-] Distribution non prise en charge ($os). Installez tmux manuellement." 
        ;;
    esac
}

check_tmux () {
    if ! command -v tmux &>/dev/null; then
        echo "l'outil tmux n'est pas installé. Lancement de l'installation..."
        installer_tmux
        check_tmux
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

ecoute_annonce () {
while true;do
local annonce="/tmp/annonce_recu"
nc -l -p "$PORT3" > "$annonce" 2>/dev/null
sleep 0.2 # pour donner le temps à nc de tout écrire
local contenu=$(cat "$annonce" | grep "^Joueur") 
if [ -n "$contenu" ]; then
        local maintenant=$(date +%s)
        local nom_joueur=$(echo "$contenu" | cut -d':' -f2)
        local ip_joueur=$(echo "$contenu" | cut -d':' -f3)

          # 1. On supprime l'ancienne entrée de ce joueur si elle existe déjà
        if [ -f "$fichier_joueur" ]; then
        	sed -i "/^Joueur:${nom_joueur}:${ip_joueur}:/d" "$fichier_joueur"
        	echo "Joueur:${nom_joueur}:${ip_joueur}:${maintenant}" >> "$fichier_joueur"  #On ajoute la ligne avec le temps en seconde actuel à la fin
         fi 
fi
#Nettoyage automatique des joueurs déconnectés (> 10 secondes)
        nettoyer_joueurs_inactifs
    done
}

 envoie_annonce () {
 local joueur="$prenom"
 local mon_ip=$(hostname -I | awk '{printf $1}')
 local base=$(echo "$mon_ip" | sed 's/\.[0-9]*$//')
 
 while true;do
   for i in {1..254};do
   local cible="${base}.${i}"
   [ "$cible" = "$mon_ip" ] && continue 
   echo "Joueur:${joueur}:${mon_ip}" | nc -w 1 "$cible" "$PORT3" 2>/dev/null &
   done
 wait
 sleep 10
 done
 }
 
 nettoyer_joueurs_inactifs () {
    [ ! -f "$fichier_joueur" ] && return
    local maintenant=$(date +%s)
    local fichier_temporaire="/tmp/Joueurs.tmp"
        > "$fichier_temporaire"  # vider proprement
    while IFS=':' read -r prefixe nom ip sent_time; do
        [ -z "$prefixe" ] && continue
        
        # Calcul de la différence de temps
        local difference=$(( maintenant - sent_time ))
        # Si le joueur a envoyé un signe il y a moins de 11 secondes, on le garde
        # (On met 11 pour éviter les micro-décalages réseau avec la boucle sleep 10 de l'expéditeur)
        if [ "$difference" -le 11 ]; then
            echo "${prefixe}:${nom}:${ip}:${sent_time}" >> "$fichier_temporaire"
        fi
    done < "$fichier_joueur"

    # On remplace l'ancien fichier par le fichier propre
    mv "$fichier_temporaire" "$fichier_joueur"
}

