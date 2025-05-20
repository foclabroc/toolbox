#!/bin/bash

BACKTITLE="Foclabroc Toolbox"
UPGRADE_DIR="/userdata/system/upgrade"
DEST_FILE="$UPGRADE_DIR/boot.tar.xz"

declare -A poids_versions=(
    [31]=1810
    [35]=2520
    [36]=2730
    [37]=2900
    [38]=3020
    [39]=3160
    [40]=3340
    [41]=3400
)

# Message initial
dialog --backtitle "$BACKTITLE" \
  --title "Mise à jour / Downgrade Batocera" \
  --yesno "\nScript de mise à jour ou Downgrade de Batocera.\n\nPermet de monter ou descendre la version de votre Batocera facilement si votre version actuelle ne vous convient pas.\n\nÊtes-vous sûr de vouloir continuer ?" 13 70 2>&1 >/dev/tty
if [ $? -ne 0 ]; then clear; exit 0; fi

# Fonction: vérifier connexion Internet
verifier_connexion() {
  if ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "\nPas de connexion Internet." 7 40 2>&1 >/dev/tty
    clear; exit 1
  fi
}

# Fonction: sélectionner version
selectionner_version() {
  choix=$(dialog --backtitle "$BACKTITLE" --title "Choisir une version" --menu "\nVersion actuelle : $VERSION\n\nSélectionnez une version à télécharger :\n " 20 55 8 \
    31 "->Version 31 (1.81 Go)" \
    35 "->Version 35 (2.52 Go)" \
    36 "->Version 36 (2.73 Go)" \
    37 "->Version 37 (2.90 Go)" \
    38 "->Version 38 (3.02 Go)" \
    39 "->Version 39 (3.16 Go)" \
    40 "->Version 40 (3.34 Go)" \
    41 "->Version 41 (3.40 Go)" \
    2>&1 >/dev/tty)
  numero_version="$choix"
}

# Fonction: vérifier espace libre dans /userdata (pour téléchargement)
verifier_espace_userdata() {
  poids=${poids_versions[$numero_version]}
  espace_libre=$(df -Pm /userdata | awk 'NR==2 {print $4}')
  if (( espace_libre < poids + 10 )); then
    dialog --backtitle "$BACKTITLE" --title "Erreur espace disque" --msgbox "\nEspace libre insuffisant dans /userdata.\nLibre : ${espace_libre} Mo\nRequis : ${poids} Mo" 9 60 2>&1 >/dev/tty
    clear; exit 1
  fi
}

# Fonction: vérifier espace libre dans /boot (pour extraction)
verifier_espace_boot() {
  taille_archive=${poids_versions[$numero_version]}
  taille_min_requise_boot=$((taille_archive + 200))
  espace_libre_boot=$(df -Pm /boot | awk 'NR==2 {print $4}')
  if (( espace_libre_boot < taille_min_requise_boot )); then
    dialog --backtitle "$BACKTITLE" --title "\nEspace insuffisant dans /boot" --msgbox \
      "Espace libre sur /boot : ${espace_libre_boot} Mo\nRequis : ${taille_min_requise_boot} Mo\n\nAugmenter la taille de votre boot\nou mettez à jour manuelement en vous référant\nau wiki de batocera." 15 60 2>&1 >/dev/tty
    clear; exit 1
  fi
}

# Fonction: télécharger fichier avec barre de progression dialog (infos vitesse, taille, temps restant)
telecharger_fichier() {
  url="https://foclabroc.freeboxos.fr:55973/share/wz8r37M_mq6Y5inK/boot-${numero_version}.tar.xz"
  poids=${poids_versions[$numero_version]} # en Mo
  poids_bytes=$((poids * 1024 * 1024))

  mkdir -p "$UPGRADE_DIR"
  rm -f "$DEST_FILE"

  (
    curl -sL "$url" -o "$DEST_FILE" &
    PID_CURL=$!
    START_TIME=$(date +%s)

    while kill -0 $PID_CURL 2>/dev/null; do
      if [ -f "$DEST_FILE" ]; then
        CURRENT_SIZE=$(stat -c%s "$DEST_FILE" 2>/dev/null)
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        [ "$ELAPSED" -eq 0 ] && ELAPSED=1

        SPEED_BPS=$((CURRENT_SIZE / ELAPSED))
        SPEED_MO=$(echo "scale=2; $CURRENT_SIZE / $ELAPSED / 1048576" | bc)
        CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
        TOTAL_MB=$poids
        REMAINING_BYTES=$((poids_bytes - CURRENT_SIZE))
        [ "$SPEED_BPS" -eq 0 ] && SPEED_BPS=1

        ETA_SEC=$((REMAINING_BYTES / SPEED_BPS))
        ETA_MIN=$((ETA_SEC / 60))
        ETA_REST_SEC=$((ETA_SEC % 60))
        ETA_FORMAT=$(printf "%02d:%02d" "$ETA_MIN" "$ETA_REST_SEC")

        PROGRESS=$((CURRENT_SIZE * 100 / poids_bytes))
        [ "$PROGRESS" -gt 100 ] && PROGRESS=100

        echo "XXX"
        echo -e "\n\nTéléchargement de la version $numero_version..."
        echo ""
        echo -e "Vitesse : ${SPEED_MO} Mo/s | Téléchargé : ${CURRENT_MB} / ${TOTAL_MB} Mo"
        echo ""
        echo -e "Temps restant estimé : ${ETA_FORMAT}"
        echo "XXX"
        echo "$PROGRESS"
      fi
      sleep 0.5
    done

    wait $PID_CURL
    RET=$?
    if [ $RET -ne 0 ]; then
      rm -f "$DEST_FILE"
      echo "XXX"
      echo "Erreur pendant le téléchargement."
      echo "XXX"
      sleep 2
      exit 1
    fi
  ) | dialog --backtitle "$BACKTITLE" --title "Téléchargement" --gauge "Téléchargement en cours..." 13 70 0 2>&1 >/dev/tty

  if [ ! -f "$DEST_FILE" ]; then
    dialog --backtitle "$BACKTITLE" --title "Annulé" --msgbox "\nTéléchargement annulé ou échoué." 7 40 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Fonction: extraction avec affichage fichiers extraits dans dialog gauge
extraire_et_mettre_a_jour() {
  verifier_espace_boot

  dialog --backtitle "$BACKTITLE" --infobox "\nPassage en mode lecture-écriture de la partition Boot..." 6 50 2>&1 >/dev/tty
  sleep 2
  if ! mount -o remount,rw /boot; then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "\nImpossible de remonter /boot en lecture-écriture." 8 50 2>&1 >/dev/tty
    clear; exit 1
  fi

  dialog --backtitle "$BACKTITLE" --infobox "\nSauvegarde des fichiers de configuration..." 6 40 2>&1 >/dev/tty
  sleep 2

  BOOTFILES="config.txt batocera-boot.conf"
  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}" ]; then
      cp "/boot/${BOOTFILE}" "/boot/${BOOTFILE}.upgrade" || {
        dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "\nErreur lors de la sauvegarde de $BOOTFILE" 7 50 2>&1 >/dev/tty
        clear; exit 1
      }
    fi
  done

  dialog --backtitle "$BACKTITLE" --infobox "\nAnalyse du boot.tar.xz V$numero_version avant extraction patientez..." 5 60 2>&1 >/dev/tty

  TOTAL_FILES=$(tar -tf "$DEST_FILE" | wc -l)
  [ "$TOTAL_FILES" -eq 0 ] && TOTAL_FILES=1
  COUNT=0

  (
    tar -xvf "$DEST_FILE" --no-same-owner -C /boot | while read -r file; do
      COUNT=$((COUNT + 1))
      PERCENT=$((COUNT * 100 / TOTAL_FILES))
      echo "XXX"
      echo "$PERCENT"
      echo ""
      echo "Extraction en cours... (Fichier Batocera.update lent car volumineux) patience..."
      echo ""
      echo "Fichier extrait : $file"
      echo "($COUNT / $TOTAL_FILES)"
      echo "XXX"
    done
  ) | dialog --backtitle "$BACKTITLE" --title "Extraction" --gauge "Extraction de l’archive en cours..." 12 90 0 2>&1 >/dev/tty

  dialog --backtitle "$BACKTITLE" --infobox "\nRestauration des fichiers de configuration..." 6 40 2>&1 >/dev/tty
  sleep 2
  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}.upgrade" ]; then
      if ! mv "/boot/${BOOTFILE}.upgrade" "/boot/${BOOTFILE}"; then
        dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Erreur lors de la restauration de $BOOTFILE" 7 50 2>&1 >/dev/tty
        clear
        exit 1
      fi
    fi
  done

  dialog --backtitle "$BACKTITLE" --infobox "\nRemontée de /boot en lecture seule..." 6 40 2>&1 >/dev/tty
  sleep 2
  mount -o remount,ro /boot || {
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "\nImpossible de remonter /boot en lecture seule." 7 50 2>&1 >/dev/tty
    clear; exit 1
  }

  # Supprimer l’archive téléchargée
  dialog --backtitle "$BACKTITLE" --infobox "\nNettoyage..." 5 40 2>&1 >/dev/tty
  sleep 2
  rm -f "$DEST_FILE"

  dialog --backtitle "$BACKTITLE" --title "Mise à jour terminée" --msgbox "\n\
La mise à jour est terminée, vous êtes maintenant en V${numero_version}.\n\n\
Après redémarrage :\n\
- Veuillez bien mettre à jour vos BIOS en V${numero_version}.\n\
- Mettez également à jour vos différents romsets MAME, FBNeo... en conséquence.\n\
- Et mettez à jour les systèmes tels que Switch, 3Dnes.\n" 12 90 2>&1 >/dev/tty

  dialog --backtitle "$BACKTITLE" --title "Redémarrage nécessaire" --yesno "\nUn redémarrage de Batocera est nécessaire.\n\nVoulez-vous redémarrer maintenant ?" 9 50 2>&1 >/dev/tty
  reponse=$?
  clear
  if [ "$reponse" -eq 0 ]; then
    reboot
  else
    dialog --backtitle "$BACKTITLE" --title "Annulé" --infobox "\nRedémarrage annulé par l'utilisateur." 7 40 2>&1 >/dev/tty
  fi
}

# Détecter la version actuelle de Batocera
VERSION=$(batocera-es-swissknife --version | awk '{print $1}' | sed -E 's/^([0-9]+).*/\1/')

# Confirmation après sélection de version
confirmer_version() {
  dialog --backtitle "$BACKTITLE" \
    --title "Confirmation" \
    --yesno "\nVersion de Batocera actuelle : $VERSION\n\nVoulez-vous installer la version $numero_version ?" 9 60 2>&1 >/dev/tty

  if [ $? -ne 0 ]; then
    clear
    exit 0
  fi
}

# Main
verifier_connexion
selectionner_version
confirmer_version
verifier_espace_userdata
telecharger_fichier
extraire_et_mettre_a_jour
clear
exit 0

