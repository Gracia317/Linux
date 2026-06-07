#!/bin/bash

barre_chargement() {
    echo -n "Chargement : ["
    for i in {1..25}; do
        echo -n "#"
        sleep 0.1  
    done
    echo "] Terminé! " 
} 

notif() 
{
(
 local message=$1 
 local couleur="\e[5;31m" 
 local reset="\e[0m"
 echo -ne "\e[s\e[60G${couleur}$message${reset}\e[u"
 sleep 5
 local espaces=$(printf "%${#message}s" "")
 echo -ne "\e[s\e[60G${espaces}\e[u" 
) &
}


