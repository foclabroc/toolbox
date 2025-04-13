#!/bin/bash

# Liste des jeux au format : "NomJeu|Description|Lien"
games_list=(
  "Abe|Un jeu de plateformes avec Abe l'extraterrestre|https://example.com/abe.sh"
  "Zelda 3D|Version 3D de Zelda pour nostalgique|https://example.com/zelda3d.sh"
  "Battle Tanks|Des combats de tanks en arène|https://example.com/battletanks.sh"
  "Chrono Adventure|Un RPG temporel classique|https://example.com/chrono.sh"
)

while true; do
    # Trier la liste par nom
    sorted_games=($(for game in "${games_list[@]}"; do echo "$game"; done | sort))

    # Préparer les options pour dialog
    options=()
    for game_entry in "${sorted_games[@]}"; do
        IFS="|" read -r name desc link <<< "$game_entry"
        options+=("$name" "$desc")
    done

    # Afficher la liste des jeux
    selection=$(dialog --clear --backtitle "Foclabroc Toolbox" \
        --title "Jeux disponibles à installer" \
        --menu "\nChoisissez un jeu à installer :" 20 70 10 \
        "${options[@]}" \
        2>&1 >/dev/tty)

    clear

    # Si l'utilisateur annule, on quitte
    [[ -z "$selection" ]] && break

    # Chercher le lien correspondant au nom sélectionné
    for game_entry in "${sorted_games[@]}"; do
        IFS="|" read -r name desc link <<< "$game_entry"
        if [[ "$name" == "$selection" ]]; then
            dialog --backtitle "Foclabroc Toolbox" \
                --title "Confirmation" \
                --yesno "\nVoulez-vous vraiment installer : $name ?" 8 50
            response=$?

            clear
            if [[ $response -eq 0 ]]; then
                bash <(curl -Ls "$link")
            fi
            break
        fi
    done
done

clear