#!/bin/bash

export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8

# Déclaration des jeux : clé = identifiant, valeur = "Nom affiché - Description"
declare -A jeux
jeux["->Celeste 64"]="Le retour de Madeline mais en 3D.(39.8MB)"
jeux["->Celeste pico8"]="Aidez Madeline à survivre à ses démons intérieurs au mont Celeste.(14.8MB)"
jeux["->Crash Bandicoot bit"]="Crash Bandicoot Fan-Made avec editeur de stage personnalisé.(230MB)"
jeux["->Donkey Kong Advanced"]="Un remake du jeu d'arcade classique.(19.4MB)"
jeux["->TMNT Rescue Palooza"]="TMNT: Rescue-Palooza est un jeu de beat-em-up gratuit.(168MB)"
jeux["->Spelunky"]="Spelunky jeu de plates-formes en deux dimensions. Le joueur incarne un spéléologue.(24.2MB)"
jeux["->Sonic Triple Trouble"]="Sonic Triple Touble un fangame du jeu Game Gear Sonic Triple Trouble.(115MB)"
jeux["->Pokemon Uranium"]="Fangame basé sur les series pokemon.(332MB)"

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
        --menu "\nSélectionnez un jeu à installer :\n " 20 120 10 \
        "${menu_entries[@]}" \
        2>&1 >/dev/tty)

    # Annulation = sortie du menu
    [ -z "$choix" ] && clear && exit 0

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
        esac
        sleep 2
    fi
done
