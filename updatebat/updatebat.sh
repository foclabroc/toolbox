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

# Détecter version actuelle Batocera
VERSION=$(batocera-es-swissknife --version 2>/dev/null | awk '{print $1}' | sed -E 's/^([0-9]+).*/\1/')

# Vérifier connexion internet
verifier_connexion() {
  if ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Pas de connexion Internet." 6 40 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Sélectionner version
selectionner_version() {
  choix=$(dialog --backtitle "$BACKTITLE" --title "Choisir une version" --menu "Sélectionnez une version à télécharger :" 15 50 8 \
    31 "boot-31.tar.xz" \
    35 "boot-35.tar.xz" \
    36 "boot-36.tar.xz" \
    37 "boot-37.tar.xz" \
    38 "boot-38.tar.xz" \
    39 "boot-39.tar.xz" \
    40 "boot-40.tar.xz" \
    41 "boot-41.tar.xz" \
    2>&1 >/dev/tty)

  numero_version="$choix"
}

# Confirmation oui/non après sélection version
confirmer_installation() {
  dialog --backtitle "$BACKTITLE" \
    --title "Confirmation" \
    --yesno "Version de Batocera actuelle : $VERSION\nVoulez-vous installer la version $numero_version ?" 10 60 2>&1 >/dev/tty

  if [ $? -ne 0 ]; then
    clear
    exit 0
  fi
}

# Vérifier espace disque
verifier_espace() {
  poids=${poids_versions[$numero_version]}
  espace_libre=$(df -Pm /userdata | awk 'NR==2 {print $4}')
  if (( espace_libre < poids + 10 )); then
    dialog --backtitle "$BACKTITLE" --title "Erreur espace disque" --msgbox "Espace libre insuffisant dans /userdata.\nLibre : ${espace_libre} Mo\nRequis : ${poids} Mo" 8 60 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Télécharger fichier avec progress dialog et infos détaillées
telecharger_fichier() {
  url="https://foclabroc.freeboxos.fr:55973/share/wz8r37M_mq6Y5inK/boot-${numero_version}.tar.xz"
  poids=${poids_versions[$numero_version]}
  mkdir -p "$UPGRADE_DIR"
  rm -f "$DEST_FILE"

  (
    curl -sL "$url" -o "$DEST_FILE" &
    PID_CURL=$!
    START_TIME=$(date +%s)
    FILE_SIZE=$((poids * 1024 * 1024))
    while kill -0 $PID_CURL 2>/dev/null; do
      if [ -f "$DEST_FILE" ]; then
        CURRENT_SIZE=$(stat -c%s "$DEST_FILE" 2>/dev/null)
        NOW=$(date +%s)
        ELAPSED=$((NOW - START_TIME))
        [ "$ELAPSED" -eq 0 ] && ELAPSED=1
        SPEED_BPS=$((CURRENT_SIZE / ELAPSED))
        SPEED_MO=$(echo "scale=2; $CURRENT_SIZE / $ELAPSED / 1048576" | bc)
        CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
        TOTAL_MB=$((FILE_SIZE / 1024 / 1024))
        REMAINING_BYTES=$((FILE_SIZE - CURRENT_SIZE))
        [ "$SPEED_BPS" -eq 0 ] && SPEED_BPS=1
        ETA_SEC=$((REMAINING_BYTES / SPEED_BPS))
        ETA_MIN=$((ETA_SEC / 60))
        ETA_REST_SEC=$((ETA_SEC % 60))
        ETA_FORMAT=$(printf "%02d:%02d" "$ETA_MIN" "$ETA_REST_SEC")

        PROGRESS_DL=$((CURRENT_SIZE * 90 / FILE_SIZE))
        PROGRESS=$((10 + PROGRESS_DL))
        [ "$PROGRESS" -gt 100 ] && PROGRESS=100

        echo "XXX"
        echo -e "\n\nTéléchargement de boot-$numero_version.tar.xz..."
        echo -e "\nVitesse : ${SPEED_MO} Mo/s | Téléchargé : ${CURRENT_MB} / ${TOTAL_MB} Mo"
        echo -e "Temps restant estimé : ${ETA_FORMAT}"
        echo "XXX"
        echo "$PROGRESS"
      fi
      sleep 0.5
    done

    wait $PID_CURL
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      rm -f "$DEST_FILE"
      echo "XXX"
      echo "Erreur pendant le téléchargement."
      echo "XXX"
      sleep 2
      exit 1
    fi
  ) | dialog --backtitle "$BACKTITLE" --title "Téléchargement" --gauge "Téléchargement de la version $numero_version..." 10 60 0 2>&1 >/dev/tty

  if [ ! -f "$DEST_FILE" ]; then
    dialog --backtitle "$BACKTITLE" --title "Annulé" --msgbox "Téléchargement annulé ou échoué." 6 40 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Extraire et mettre à jour /boot avec sauvegarde/restauration configs
extraire_et_mettre_a_jour() {
  echo "remounting /boot in rw"
  if ! mount -o remount,rw /boot; then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Impossible de remonter /boot en lecture-écriture." 6 50 2>&1 >/dev/tty
    clear
    exit 1
  fi

  dialog --backtitle "$BACKTITLE" --infobox "Sauvegarde des fichiers de configuration..." 5 50 2>&1 >/dev/tty
  sleep 1

  BOOTFILES="config.txt batocera-boot.conf"
  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}" ]; then
      cp "/boot/${BOOTFILE}" "/boot/${BOOTFILE}.upgrade" || {
        dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Impossible de sauvegarder $BOOTFILE." 6 50 2>&1 >/dev/tty
        clear
        exit 1
      }
    fi
  done

  taille_archive=${poids_versions[$numero_version]}
  taille_min_requise_boot=$((taille_archive + 200))
  espace_libre_boot=$(df -Pm /boot | awk 'NR==2 {print $4}')
  if (( espace_libre_boot < taille_min_requise_boot )); then
    dialog --backtitle "$BACKTITLE" \
           --title "Espace insuffisant dans /boot" \
           --msgbox "Espace libre sur /boot : ${espace_libre_boot} Mo\nRequis : ${taille_min_requise_boot} Mo (archive + marge de 200 Mo)" 10 60 2>&1 >/dev/tty
    clear
    exit 1
  fi

  dialog --backtitle "$BACKTITLE" --title "Extraction" --infobox "Extraction de l'archive dans /boot..." 5 50 2>&1 >/dev/tty
  sleep 1

  if ! (cd /boot && xz -dc < "$DEST_FILE" | tar xvf - --no-same-owner); then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Erreur lors de l'extraction." 6 50 2>&1 >/dev/tty
    clear
    exit 1
  fi

  dialog --backtitle "$BACKTITLE" --infobox "Restauration des fichiers de configuration..." 5 50 2>&1 >/dev/tty
  sleep 1
  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}.upgrade" ]; then
      mv "/boot/${BOOTFILE}.upgrade" "/boot/${BOOTFILE}" || echo "Erreur restauration $BOOTFILE" >&2
    fi
  done

  dialog --backtitle "$BACKTITLE" --infobox "Remontée de /boot en lecture seule..." 5 50 2>&1 >/dev/tty
  sleep 1
  mount -o remount,ro /boot || {
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Impossible de remonter /boot en lecture seule." 6 50 2>&1 >/dev/tty
    clear
    exit 1
  }

  rm -f "$DEST_FILE"

  dialog --backtitle "$BACKTITLE" --title "Succès" --msgbox "Mise à jour vers la version $numero_version effectuée avec succès !" 8 50 2>&1 >/dev/tty

  dialog --backtitle "$BACKTITLE" \
    --title "Redémarrage nécessaire" \
    --yesno "Un redémarrage de Batocera est nécessaire.\n\nVoulez-vous redémarrer maintenant ?" 8 50 2>&1 >/dev/tty

  reponse=$?
  clear
  if [ "$reponse" -eq 0 ]; then
    reboot
  else
    echo "Redémarrage annulé par l'utilisateur."
  fi
}

# --- Main ---

verifier_connexion
selectionner_version
confirmer_installation
verifier_espace
telecharger_fichier
extraire_et_mettre_a_jour
