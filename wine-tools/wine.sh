#!/bin/bash

# Define the options
OPTIONS=(
  "1" "Telechargement Runner Wine (vanilla/regular) builds [Kron4ek/Wine-Builds]"
  "2" "Telechargement Runner Wine-TKG-Staging builds [Kron4ek/Wine-Builds/tkg]"
  "3" "Telechargement Runner Wine-GE Custom builds [GloriousEggroll/wine-ge-custom]"
  "4" "Telechargement Runner GE-Proton builds [GloriousEggroll/proton-ge-custom]"
  "5" "Telechargement Runner GE-Custom de la V40 (pour garder vos anciennes bottles/sauvegarde)"
  "6" "Installation de Winetricks personnalisé"
  "7" "Convertir dossier .pc en dossier .wine"
  "8" "Compresser dossier .wine en fichier .wsquashfs ou .tgz"
  "9" "Decompresser fichiers .wsquashfs ou .wtgz en dossier .wine"
  "10" "Suppression de runners custom inutiles dans /system/wine/custom"
  "11" "Suppression de bouteilles .wine .wsquashfs .wtgz dans /system/wine-bottle/windows"
)

# Use dialog to display the menu
CHOICE=$(dialog --clear --backtitle "Foclabroc Toolbox" \
                --title "Wine Toolbox" \
                --menu "\nChoisissez une option:\n " \
               22 106 11 \
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
        #echo "Winetricks."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/tricks.sh | bash
        ;;
    7)
        #echo ".pc to .wine."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/pc-to-wine.sh | bash
        ;;
    8)
        #echo ".wine to .squashFS."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/squash.sh | bash
        ;;
    9)
        #echo ".squashFS to .wine."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/unsquash.sh | bash
        ;;
    10)
        #echo "Suppression runner."
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/delete-runner.sh | bash
        ;;
    11)
        #echo "Suppression bottle"
        curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/delete-bottle.sh | bash
        ;;
    *)
        echo "Invalid choice or no choice made. Exiting."
        ;;
esac
