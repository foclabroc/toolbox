#!/bin/bash

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

# Déclaration des jeux : clé = identifiant, valeur = "Nom affiché - Description"
declare -A jeux
jeux["->Celeste 64"]="Le retour de Madeline mais en 3D.(39.8Mo)"
jeux["->Celeste pico8"]="Aidez Madeline à survivre à ses démons intérieurs au mont Celeste.(14.8Mo)"
jeux["->Crash Bandicoot bit"]="Crash Bandicoot Fan-Made avec editeur de stage personnalisé.(230Mo)"
jeux["->Donkey Kong Advanced"]="Un remake du jeu d'arcade classique.(19.4MB)"
jeux["->TMNT Rescue Palooza"]="TMNT: Rescue-Palooza est un jeu de beat-em-up gratuit.(168MB)"
jeux["->Spelunky"]="Spelunky jeu de plates-formes en deux dimensions. Le joueur incarne un spéléologue.(24.2Mo)"
jeux["->Sonic Triple Trouble"]="Sonic Triple Touble un fangame du jeu Game Gear Sonic Triple Trouble.(115Mo)"
jeux["->Pokemon Uranium"]="Fangame basé sur les series pokemon.(332Mo)"
jeux["->MiniDoom 2"]="Le jeu hommage qui transforme DOOM en un jeu de plateforme d'action.(114Mo)"
jeux["->AM2R"]="Another Metroid 2 Remake, remake non officiel du jeu Game Boy de 1991 Metroid II.(85.6Mo)"
jeux["->Megaman X II"]="Mega Man X Innocent Impulse FanGame style 8bits.(354Mo)"
jeux["->Super Tux Kart"]="Mario Kart like, opensource avec mode online.(662Mo)"
jeux["->Street of Rage R 5.2"]="Remake de Street Of Rage 1/2/3 pour Windows.(331Mo)"
jeux["->Megaman 2.5D"]="Fangame de Mega Man en 2.5D pour Windows.(855Mo)"
jeux["->Sonic Smackdown"]="Fangame de combat, faite combattre vos heros de l'univers Sonic.(1.6Go)"
jeux["->Maldita Castilla"]="Fanmade dans le style de Ghouls 'n Ghosts.(60.2Mo)"
jeux["->Super Smash Crusade"]="Fanmade Super Smash Bros Crusade.(1.45Go)"
jeux["->Rayman Redemption"]="Fanmade Rayman Redemption.(976Mo)"
jeux["->Power Bomberman"]="Fanmade de Bomberman.(616Mo)"
jeux["->Mushroom Kingdom Fusion"]="Fanmade Mario croisé avec de nombreuses autres franchises de jeux.(962Mo)"
jeux["->Dr. Robotnik's Racers"]="Fanmade Mario Kart like dans l'univers de Sonic.(698Mo)"


while true; do
    # Construction dynamique du menu trié alphabétiquement par clé
    menu_entries=()
    IFS=$'\n' sorted_keys=($(printf "%s\n" "${!jeux[@]}" | sort))
    for key in "${sorted_keys[@]}"; do
        menu_entries+=("$key" "${jeux[$key]}")
    done

    # Affichage du menu principal
    choix=$(dialog --clear --backtitle "Foclabroc Toolbox" \
        --title "Jeux disponibles" \
        --menu "\nSélectionnez un jeu à installer :\n " 33 124 10 \
        "${menu_entries[@]}" \
        2>&1 >/dev/tty)

    # Annulation = sortie du menu
    if [ -z "$choix" ]; then
        clear
        curl -s http://127.0.0.1:1234/reloadgames
        exit 0
    fi

    # Confirmation d'installation
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" \
        --yesno "\nVoulez-vous installer :\n\n$choix ?" 10 50 2>&1 >/dev/tty

    if [ $? -eq 0 ]; then
        clear
        case $choix in
            "->Celeste 64")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/c64.sh | bash
                ;;
            "->Celeste pico8")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/celeste.sh | bash
                ;;
            "->Crash Bandicoot bit")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/cbit.sh | bash
                ;;
            "->Donkey Kong Advanced")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/dka.sh | bash
                ;;
            "->TMNT Rescue Palooza")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/tmntrp.sh | bash
                ;;
            "->Sonic Triple Trouble")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/stt.sh | bash
                ;;
            "->Spelunky")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/spelunky.sh | bash
                ;;
            "->Pokemon Uranium")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/pokeura.sh | bash
                ;;
            "->MiniDoom 2")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/minidoom2.sh | bash
                ;;
            "->AM2R")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/am2r.sh | bash
                ;;
            "->Megaman X II")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/mmxii.sh | bash
                ;;
            "->Super Tux Kart")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/supertuxkart.sh | bash
                ;;
            "->Street of Rage R 5.2")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/sorr52.sh | bash
                ;;
            "->Megaman 2.5D")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/megaman25.sh | bash
                ;;
            "->Sonic Smackdown")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/sonicsmash.sh | bash
                ;;
            "->Maldita Castilla")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/maldita.sh | bash
                ;;
            "->Super Smash Crusade")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/supersc.sh | bash
                ;;
            "->Rayman Redemption")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/raymanr.sh | bash
                ;;
            "->Power Bomberman")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/powerb.sh | bash
                ;;
            "->Mushroom Kingdom Fusion")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/mushkf.sh | bash
                ;;
            "->Dr. Robotnik's Racers")
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/drrobo.sh | bash
                ;;
        esac
        sleep 2
    fi
done