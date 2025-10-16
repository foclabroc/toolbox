#!/bin/bash

URL_FP="https://github.com/foclabroc/toolbox/releases/download/Fichiers/fpinball.zip"

clear

# Détection de la version Batocera
VERSION=$(batocera-es-swissknife --version | awk '{print $1}' | sed -E 's/^([0-9]+).*/\1/')

dialog --backtitle "Foclabroc Toolbox" \
       --infobox "\nVersion de Batocera détectée : $VERSION" 6 50 2>&1 >/dev/tty
sleep 2

# Déterminer l'URL en fonction de la version
if [ "$VERSION" -ge 42 ]; then
    ARCHIVE_URL="$URL_FP"
else
    dialog --backtitle "Foclabroc Toolbox" \
           --msgbox "\nVotre version de Batocera ($VERSION) n'est pas prise en charge.\n\nMettez à jour vers la version 42 ou supérieure." 8 60 2>&1 >/dev/tty
    exit 1
fi

# Nom du fichier
ARCHIVE_NAME=$(basename "$ARCHIVE_URL")

# Chemin de destination
DESTINATION="/userdata/"

# Suppression des anciens dossiers
dialog --backtitle "Foclabroc Toolbox" \
       --infobox "\nSuppression des anciens fichiers..." 5 50 2>&1 >/dev/tty
sleep 1
rm -rf /userdata/system/wine-bottles/fpinball
rm -rf /userdata/system/pro/fpinball

# Lancement du téléchargement
(
  curl -L --progress-bar -o "$DESTINATION$ARCHIVE_NAME" "$ARCHIVE_URL" 2>&1 | \
  stdbuf -oL tr '\r' '\n' | awk '/%/ {gsub(/%/,""); print $1}'
) | dialog --gauge "Téléchargement de l'archive Future Pinball en cours..." 7 60 0 2>&1 >/dev/tty
# Vérifier si le téléchargement a réussi
if [ $? -ne 0 ] || [ ! -f "$DESTINATION$ARCHIVE_NAME" ]; then
    dialog --backtitle "Foclabroc Toolbox" \
           --msgbox "\nÉchec du téléchargement de l'archive !" 6 50 2>&1 >/dev/tty
    exit 1
fi

# Décompression avec jauge de progression (toutes les 10 lignes)
TOTAL_FILES=$(unzip -l "$DESTINATION$ARCHIVE_NAME" | grep -E "^[ ]*[0-9]" | wc -l)
COUNT=0

(
  unzip -o "$DESTINATION$ARCHIVE_NAME" -d "$DESTINATION" | grep -E "inflating|extracting" | while read -r line; do
      COUNT=$((COUNT + 1))
      if (( COUNT % 10 == 0 )); then
          PERCENT=$((COUNT * 100 / TOTAL_FILES))
          echo "$PERCENT"
      fi
  done
) | dialog --gauge "Extraction de l'archive Future Pinball..." 7 60 0 2>&1 >/dev/tty

# Nettoyage du fichier ZIP
dialog --backtitle "Foclabroc Toolbox" \
       --infobox "\nNettoyage des fichiers temporaires..." 5 50 2>&1 >/dev/tty
sleep 1
rm -f "$DESTINATION$ARCHIVE_NAME"

sleep 1


##############################################################
#  Installation automatique de Wine GE-Custom V40
##############################################################

# === Définir les URLs pour les fichiers split ===
URL_PART1="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.001"
URL_PART2="https://github.com/foclabroc/toolbox/raw/refs/heads/main/wine-tools/ge-customv40.tar.xz.002"

# === Définir les répertoires ===
DOWNLOAD_DIR="/tmp/ge-custom-download"
EXTRACT_DIR="/userdata/system/wine/custom"
FINAL_DIR="$EXTRACT_DIR/ge-custom"

# === Vérifier si Wine GE-Custom est déjà installé ===
if [[ -d "$FINAL_DIR" ]]; then
    dialog --backtitle "Foclabroc Toolbox" \
    --infobox "\nWine GE-Custom est déjà installé.\nAucune action nécessaire." 6 60 2>&1 >/dev/tty
    sleep 2

    # === Message final ===
    dialog --backtitle "Foclabroc Toolbox" --title "Future Pinball" \
    --msgbox "Installation de Future Pinball terminée avec succès.\n\nAu premier lancement, patientez 30 secondes à 1 minute\npour l'installation automatique des Winetricks." 10 70 2>&1 >/dev/tty

    # === Rafraîchissement des jeux ===
    curl -s http://127.0.0.1:1234/reloadgames > /dev/null
    exit 0
fi

# === Création des répertoires ===
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$EXTRACT_DIR"

# === Message d'information ===
dialog --backtitle "Foclabroc Toolbox" --infobox "\nTéléchargement et installation du runner compatible Future Pinball..." 6 60 2>&1 >/dev/tty
sleep 2

# === Téléchargement des 2 parties ===
(
  echo 10
  curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" "$URL_PART1" --progress-bar && echo 50
  curl -Ls -o "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" "$URL_PART2" --progress-bar && echo 100
) | dialog --gauge "Téléchargement de Wine GE-Custom en cours..." 7 55 0 2>&1 >/dev/tty

# === Vérification des téléchargements ===
if [[ ! -f "$DOWNLOAD_DIR/ge-customv40.tar.xz.001" || ! -f "$DOWNLOAD_DIR/ge-customv40.tar.xz.002" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur lors du téléchargement de Wine GE-Custom !" 5 55 2>&1 >/dev/tty
    exit 1
fi

# === Assemblage des fichiers ===
cd "$DOWNLOAD_DIR" || exit 1
dialog --backtitle "Foclabroc Toolbox" --infobox "\nAssemblage des fichiers..." 5 55 2>&1 >/dev/tty
sleep 1
cat ge-customv40.tar.xz.001 ge-customv40.tar.xz.002 > ge-customv40.tar.xz

if [[ ! -f "ge-customv40.tar.xz" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nÉchec de l'assemblage des fichiers !" 5 55 2>&1 >/dev/tty
    exit 1
fi

# === Décompression du .xz ===
dialog --backtitle "Foclabroc Toolbox" --infobox "\nDécompression de l'archive .xz..." 5 55 2>&1 >/dev/tty
xz -d ge-customv40.tar.xz

if [[ ! -f "ge-customv40.tar" ]]; then
    dialog --backtitle "Foclabroc Toolbox" --infobox "\nErreur lors de la décompression du .xz !" 5 55 2>&1 >/dev/tty
    exit 1
fi

# === Suppression ancien dossier ===
rm -rf "$FINAL_DIR"

# === Extraction avec jauge de progression (toutes les 50 fichiers extraits) ===
TOTAL_FILES=$(tar -tf ge-customv40.tar | wc -l)
COUNT=0

(
  tar -tf ge-customv40.tar | while read -r file; do
      COUNT=$((COUNT + 1))
      # Extraire le fichier courant
      tar -xf ge-customv40.tar -C "$EXTRACT_DIR" "$file"
      # Mettre à jour la jauge toutes les 50 extractions
      if (( COUNT % 50 == 0 )); then
          PERCENT=$((COUNT * 100 / TOTAL_FILES))
          echo "$PERCENT"
      fi
  done
) | dialog --gauge "Extraction de Wine GE-Custom..." 7 55 0 2>&1 >/dev/tty

# === Vérification de l'installation ===
if [[ $? -eq 0 && -d "$FINAL_DIR" ]]; then
    dialog --backtitle "Foclabroc Toolbox" \
    --infobox "\nInstallation de Wine GE-Custom pour Future Pinball terminée avec succès !" 6 60 2>&1 >/dev/tty
    sleep 3
else
    dialog --backtitle "Foclabroc Toolbox" \
    --infobox "\nÉchec de l'installation de Wine GE-Custom V40 !" 4 55 2>&1 >/dev/tty
    exit 1
fi

# === Nettoyage ===
cd /tmp || exit 1
rm -rf "$DOWNLOAD_DIR"

# === Message final ===
dialog --backtitle "Foclabroc Toolbox" --title "Future Pinball" \
--msgbox "Installation de Future Pinball terminée avec succès.\n\nAu premier lancement, patientez 30 secondes à 1 minute\npour l'installation automatique des Winetricks." 10 70 2>&1 >/dev/tty

# === Rafraîchissement des jeux ===
curl -s http://127.0.0.1:1234/reloadgames > /dev/null

exit 0

