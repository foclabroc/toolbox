#!/bin/bash

export DIALOGRC="/userdata/system/pro/extra/.dialogrc"
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

base_url="https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows"

declare -A jeux
jeux["->Celeste 64"]="Le retour de Madeline mais en 3D.(39.8Mo)###c64.sh"
jeux["->Celeste pico8"]="Aidez Madeline à survivre à ses démons intérieurs au mont Celeste.(14.8Mo)###celeste.sh"
jeux["->Crash Bandicoot bit"]="Crash Bandicoot Fan-Made avec éditeur de stage personnalisé.(230Mo)###cbit.sh"
jeux["->Donkey Kong Advanced"]="Un remake du jeu d'arcade classique.(19.4MB)###dka.sh"
jeux["->TMNT Rescue Palooza"]="TMNT: Rescue-Palooza est un jeu de beat-em-up gratuit.(168MB)###tmntrp.sh"
jeux["->Spelunky"]="Spelunky jeu de plates-formes en deux dimensions. Le joueur incarne un spéléologue.(24.2Mo)###spelunky.sh"
jeux["->Sonic Triple Trouble"]="Sonic Triple Touble un fangame du jeu Game Gear Sonic Triple Trouble.(115Mo)###stt.sh"
jeux["->Pokemon Uranium"]="Fangame basé sur les séries Pokémon.(332Mo)###pokeura.sh"
jeux["->MiniDoom 2"]="Le jeu hommage qui transforme DOOM en un jeu de plateforme d'action.(114Mo)###minidoom2.sh"
jeux["->AM2R"]="Another Metroid 2 Remake, remake non officiel du jeu Game Boy de 1991 Metroid II.(85.6Mo)###am2r.sh"
jeux["->Megaman X II"]="Mega Man X Innocent Impulse FanGame style 8bits.(354Mo)###mmxii.sh"
jeux["->Super Tux Kart"]="Mario Kart like, open source avec mode online.(662Mo)###supertuxkart.sh"
jeux["->Street of Rage R 5.2"]="Remake de Street Of Rage 1/2/3 pour Windows.(331Mo)###sorr52.sh"
jeux["->Megaman 2.5D"]="Fangame de Mega Man en 2.5D pour Windows.(855Mo)###megaman25.sh"
jeux["->Sonic Smackdown"]="Fangame de combat, faites combattre vos héros de l'univers Sonic.(1.6Go)###sonicsmash.sh"
jeux["->Maldita Castilla"]="Fanmade dans le style de Ghouls 'n Ghosts.(60.2Mo)###maldita.sh"
jeux["->Super Smash Crusade"]="Fanmade Super Smash Bros Crusade.(1.45Go)###supersc.sh"
jeux["->Rayman Redemption"]="Fanmade Rayman Redemption.(976Mo)###raymanr.sh"
jeux["->Power Bomberman"]="Fanmade de Bomberman.(616Mo)###powerb.sh"
jeux["->Mushroom Kingdom Fusion"]="Fanmade Mario croisé avec de nombreuses autres franchises de jeux.(962Mo)###mushkf.sh"
jeux["->Dr. Robotnik's Racers"]="Fanmade Mario Kart like dans l'univers de Sonic.(698Mo)###drrobo.sh"

while true; do
    menu_entries=()
    IFS=$'\n' sorted_keys=($(printf "%s\n" "${!jeux[@]}" | sort))
    for key in "${sorted_keys[@]}"; do
        desc="${jeux[$key]%%###*}"
        menu_entries+=("$key" "$desc")
    done

    choix=$(dialog --clear --backtitle "Foclabroc Toolbox" \
        --title "Jeux disponibles" \
        --menu "\nSélectionnez un jeu à installer :\n " 33 124 15 \
        "${menu_entries[@]}" \
        2>&1 >/dev/tty)

    [ -z "$choix" ] && { curl -s http://127.0.0.1:1234/reloadgames; clear; exit 0; }

    valeur="${jeux[$choix]}"
    script="${valeur##*###}"

    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" \
        --yesno "\nVoulez-vous vraiment installer :\n\n$choix" 10 50 2>&1 >/dev/tty

    if [ $? -eq 0 ]; then
        clear
        script_url="$base_url/$script"
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "$script_url")
        if [ "$http_code" -ne 200 ]; then
            dialog --msgbox "\nImpossible de joindre le serveur pour télécharger le script. Vérifiez la connexion." 8 60 2>&1 >/dev/tty
            sleep 2
        else
            curl -s "$script_url" | bash
        fi
    fi
done
