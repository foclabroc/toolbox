#!/bin/bash

# Define the options
OPTIONS=(
  "1" "Telechargement Runner Wine (vanilla/regular) builds"
  "2" "Telechargement Runner Wine-TKG-Staging builds"
  "3" "Telechargement Runner Wine-GE Custom builds"
  "4" "Telechargement Runner GE-Proton builds"
  "5" "Telechargement Runner GE-Custom de la V40 (pour garder vos anciennes bottles/sauvegarde)"
  "6" "Sélectionnez et supprimer les runner custom inutiles"
  "7" "Installation de Winetricks personnalisé"
  "8" "Convertir dossier .pc en dossier .wine"
  "9" "Compresser dossier .wine en fichier .wsquashfs ou .tgz"
  "10" "Decompresser fichiers .wsquashfs ou .tgz en dossier .wine"
)

# Use dialog to display the menu
CHOICE=$(dialog --clear --backtitle "Foclabroc Toolbox" \
                --title "Wine Toolbox" \
                --menu "\nChoisissez une option:\n " \
               22 106 10 \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

# Clear the dialog artifacts
clear

# Run the appropriate script based on the user's choice
case $CHOICE in
    1)
        #echo "Liste Wine Vanilla and Proton."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/vanilla.sh | bash
        ;;
    2)
        #echo "Liste Wine-tkg staging."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/tkg.sh | bash
        ;;
    3)
        #echo "Liste Wine-GE Custom."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine-ge.sh | bash
        ;;
    4)
        #echo "Liste GE-Proton."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/ge-proton.sh | bash
        ;;
    5)
        #echo "Ge-custom V40."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/v40wine.sh | bash
        ;;
    6)
        #echo "Suppression runner."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/delete-runner.sh | bash
        ;;
    7)
        #echo "Winetricks."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/tricks.sh | bash
        ;;
    8)
        #echo ".pc to .wine."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/pc-to-wine.sh | bash
        ;;
    9)
        echo "You chose to convert a .pc folder to a .wine folder."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wc.sh | bash
        ;;
    10)
        echo "You chose to compress a .wine folder to a .wsquashfs or .tgz file."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/squash.sh | bash
        ;;
    *)
        echo "Invalid choice or no choice made. Exiting."
        ;;
esac
