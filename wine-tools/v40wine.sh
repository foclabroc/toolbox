#!/bin/bash

# Définir les URLs pour les fichiers split
URL_PART1="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.002"

# Définir le répertoire de téléchargement et le chemin de destination pour l'extraction
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"

# Créer les répertoires
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

# Demander à l'utilisateur s'il souhaite lancer le téléchargement
dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "Souhaitez-vous télécharger et installer ge-custom V40 ?" 7 60

# Si l'utilisateur appuie sur "Non" (retourne 1)
if [[ $? -eq 1 ]]; then
    (
        dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60
        sleep 1
    ) 2>&1 >/dev/tty
    # Lancer le script précédent (ici tu retournes dans le menu Wine Tools)
    curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
    exit 0
fi

# Téléchargement des 2 parties
(
  echo 10 ; curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" "$URL_PART1" --progress-bar && echo 50
  curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" "$URL_PART2" --progress-bar && echo 100
) | dialog --gauge "Téléchargement de ge-custom v40 en cours..." 7 55 0

# Vérification de la réussite des téléchargements
if [[ ! -f "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" || ! -f "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur lors du téléchargement des fichiers!" 5 55
    exit 1
fi

# Assemblage des 2 parties
cd "$DOWNLOAD_DIR"
dialog --backtitle "Foclabroc Toolbox" --infobox "\nAssemblage des 2 parties en cours..." 5 55
sleep 2
cat ge-customv40.tar.xz.001 ge-customv40.tar.xz.002 > ge-customv40.tar.xz

# Vérification de l'assemblage
if [[ ! -f "ge-customv40.tar.xz" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de l'assemblage des 2 parties !!!" 5 55
	sleep 2
    exit 1
fi

# Décompression du .xz
dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du .xz en cours..." 5 55
sleep 2
xz -d ge-customv40.tar.xz

# Vérification du fichier décompressé
if [[ ! -f "ge-customv40.tar" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de la décompression du .xz !!!" 5 55
    exit 1
fi

# Suppression ancien dossier
rm -rf /userdata/system/wine/custom/ge-custom

# Décompression du .tar
dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression du .tar en cours..." 5 55
tar -xf ge-customv40.tar -C "$EXTRACT_DIR"

# Vérification du fichier extrait
if [[ $? -eq 0 ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nInstallation de ge-custom V40 terminée avec succès dans $EXTRACT_DIR." 6 60
    sleep 3
else
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nEchec de l'installation de ge-custom V40 !!!" 4 55
    exit 1
fi

# Nettoyage des fichiers temporaires
cd /tmp || exit 1
rm -rf "$DOWNLOAD_DIR"

# Retourner au script précédent (Menu Wine Tools)
(
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nRetour Menu Wine Tools..." 5 60
    sleep 1
) 2>&1 >/dev/tty
curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash
exit 0
