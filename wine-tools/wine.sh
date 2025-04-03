#!/bin/bash

# Define the options
OPTIONS=(
  "1" "Telechargement Runner Wine & Proton (vanilla/regular) builds"
  "2" "Telechargement Runner Wine-TKG-Staging builds"
  "3" "Telechargement Runner Wine-GE Custom builds"
  "4" "Telechargement Runner GE-Proton builds"
  "5" "Telechargement Runner GE-Custom de la version 40 (pour garder vos anciennes bottles/sauvegarde)"
  "6" "Installation de Winetricks automatique"
  "7" "Convertir dossier .pc en dossier .wine"
  "8" "Compresser dossier .wine en fichier .wsquashfs ou .tgz"
  "9" "Decompresser fichiers .wsquashfs ou .tgz en dossier .wine"
)

# Use dialog to display the menu
CHOICE=$(dialog --clear --backtitle "Foclabroc Toolbox" \
                --title "Wine Toolbox" \
                --menu "\nChoisissez une option:\n " \
               30 90 9 \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

# Clear the dialog artifacts
clear

# Run the appropriate script based on the user's choice
case $CHOICE in
    1)
        #echo "Liste Wine Vanilla and Proton."
        curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/vanilla.sh | bash
        ;;
    2)
        #echo "Liste Wine-tkg staging."
        curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/tkg.sh | bash
        ;;
    3)
        #echo "Liste Wine-GE Custom."
        curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine-ge.sh | bash
        ;;
    4)
        echo "You chose GE-Proton."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/ge-proton.sh | bash
        ;;
    5)
        echo "You chose Prepare installers next run."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/deps.sh | bash
        ;;
    6)
        echo "You chose Easy Batocera Wine Tricks."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/tricks.sh | bash
        ;;
    7)
        echo "You chose Easy autorun.cmd creator."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/ar.sh | bash
        ;;
    8)
        echo "You chose to convert a .pc folder to a .wine folder."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/wc.sh | bash
        ;;
    9)
        echo "You chose to compress a .wine folder to a .wsquashfs or .tgz file."
        curl -L https://github.com/trashbus99/profork/raw/master/wine-custom/squash.sh | bash
        ;;
    *)
        echo "Invalid choice or no choice made. Exiting."
        ;;
esac
