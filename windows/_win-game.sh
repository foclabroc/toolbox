#!/bin/bash

# Déclaration des jeux : clé = identifiant, valeur = "Nom affiché - Description"
declare -A jeux
jeux["-celeste-64"]="Le retour de Madeline mais en 3D."
jeux["-doom"]="Doom - FPS légendaire"
jeux["-mario"]="Mario Forever - Platformer fun"
jeux["-sonic"]="Sonic - Le hérisson supersonique"
jeux["-zelda"]="Zelda 3D - Aventure rétro"

while true; do
    # Construction dynamique du menu trié alphabétiquement par clé
    menu_entries=()
    for key in $(printf "%s\n" "${!jeux[@]}" | sort); do
        menu_entries+=("$key" "${jeux[$key]}")
    done

    # Affichage du menu principal
    choix=$(dialog --clear --backtitle "Foclabroc Toolbox" \
        --title "Jeux disponibles" \
        --menu "\nSélectionnez un jeu à installer :\n " 20 70 10 \
        "${menu_entries[@]}" \
        2>&1 >/dev/tty)

    # Annulation = sortie du menu
    [ -z "$choix" ] && clear && exit 0

    # Confirmation d'installation
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" \
        --yesno "\nVoulez-vous installer :\n\n${jeux[$choix]} ?" 10 50 2>&1 >/dev/tty

    if [ $? -eq 0 ]; then
        clear
        echo "Installation de ${jeux[$choix]}..."
        case $choix in
            -celeste-64)
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/c64.sh | bash
                ;;
            -doom)
                curl -Ls https://tonsite.com/scripts/doom.sh | bash
                ;;
            -mario)
                curl -Ls https://tonsite.com/scripts/mario.sh | bash
                ;;
            -sonic)
                curl -Ls https://tonsite.com/scripts/sonic.sh | bash
                ;;
            -zelda)
                curl -Ls https://tonsite.com/scripts/zelda.sh | bash
                ;;
        esac
        sleep 2
    fi
done
