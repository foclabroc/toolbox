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

# Affichage initial
dialog --backtitle "$BACKTITLE" \
  --title "Mise à jour / Downgrade Batocera" \
  --yesno "Script de mise à jour ou Downgrade de Batocera.\n\nPermet de monter ou descendre la version de votre Batocera facilement si votre version actuelle ne vous convient pas.\n\nÊtes-vous sûr de vouloir continuer ?" 12 70 2>&1 >/dev/tty

if [ $? -ne 0 ]; then
  clear
  exit 0
fi

# Fonction: vérifie la connexion Internet
verifier_connexion() {
  if ! ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
    dialog --backtitle "$BACKTITLE" --title "Erreur" --msgbox "Pas de connexion Internet." 6 40 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Fonction: sélectionne la version
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

# Fonction: vérifie l'espace disponible
verifier_espace() {
  poids=${poids_versions[$numero_version]}
  espace_libre=$(df -Pm /userdata | awk 'NR==2 {print $4}')
  if (( espace_libre < poids + 10 )); then
    dialog --backtitle "$BACKTITLE" --title "Erreur espace disque" --msgbox "Espace libre insuffisant dans /userdata.\nLibre : ${espace_libre} Mo\nRequis : ${poids} Mo" 8 60 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Fonction: confirme la version avant installation
confirmer_version() {
  # Détecter version actuelle de Batocera
  VERSION=$(batocera-es-swissknife --version | awk '{print $1}' | sed -E 's/^([0-9]+).*/\1/')

  dialog --backtitle "$BACKTITLE" \
    --title "Confirmation" \
    --yesno "Version de Batocera actuelle : $VERSION\n\nÊtes-vous sûr de vouloir installer la version $numero_version ?" 10 60 2>&1 >/dev/tty

  if [ $? -ne 0 ]; then
    clear
    exit 0
  fi
}

# Fonction: télécharge avec annulation possible et progress info dans mixedgauge
telecharger_fichier() {
  url="https://foclabroc.freeboxos.fr:55973/share/wz8r37M_mq6Y5inK/boot-${numero_version}.tar.xz"
  poids=${poids_versions[$numero_version]}
  mkdir -p "$UPGRADE_DIR"
  rm -f "$DEST_FILE"

  (
    curl -L "$url" --silent --output "$DEST_FILE" --fail &
    curl_pid=$!

    while kill -0 $curl_pid 2>/dev/null; do
      if [ -f "$DEST_FILE" ]; then
        downloaded=$(du -m "$DEST_FILE" | awk '{print $1}')
        [ "$downloaded" -gt "$poids" ] && downloaded=$poids
        percent=$((downloaded * 100 / poids))
        echo "$percent"
        echo "Téléchargement version $numero_version"
        echo "$downloaded Mo sur $poids Mo téléchargés"
        echo ""
        echo "Veuillez patienter..."
      else
        echo "0"
        echo "Téléchargement version $numero_version"
        echo "Début du téléchargement..."
        echo ""
        echo ""
      fi
      sleep 1
    done

    wait $curl_pid
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      rm -f "$DEST_FILE"
      echo "XXX"
      echo "Erreur pendant le téléchargement."
      echo "XXX"
      sleep 2
      exit 1
    fi
  ) | dialog --backtitle "$BACKTITLE" --title "Téléchargement" --mixedgauge "Progression du téléchargement" 15 70 0 2>&1 >/dev/tty

  if [ ! -f "$DEST_FILE" ]; then
    dialog --backtitle "$BACKTITLE" --title "Annulé" --msgbox "Téléchargement annulé ou échoué." 6 40 2>&1 >/dev/tty
    clear
    exit 1
  fi
}

# Fonction: mise à jour /boot avec extraction dans mixedgauge et suivi extraction
extraire_et_mettre_a_jour() {
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

  echo "remounting /boot in rw"
  if ! mount -o remount,rw /boot; then
    exit 1
  fi

  dialog --backtitle "$BACKTITLE" --infobox "Sauvegarde des fichiers de configuration..." 5 40 2>&1 >/dev/tty
  sleep 1

  BOOTFILES="config.txt batocera-boot.conf"
  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}" ]; then
      cp "/boot/${BOOTFILE}" "/boot/${BOOTFILE}.upgrade" || exit 1
    fi
  done

  # Extraction avec suivi via mixedgauge
  total_files=$(tar -tf "$DEST_FILE" | wc -l)
  count=0

  (
    echo "0"
    echo "Extraction de l'archive dans /boot"
    echo "0 / $total_files fichiers extraits"
    echo ""
    echo ""

    cd /boot || exit 1
    # Extraire en listant les fichiers, chaque fichier affiche la progression
    xz -dc < "$DEST_FILE" | tar --no-same-owner -xv | while read -r file; do
      count=$((count + 1))
      percent=$((count * 100 / total_files))
      echo "$percent"
      echo "Extraction de l'archive dans /boot"
      echo "$count / $total_files fichiers extraits"
      echo "$file"
      echo ""
      sleep 0.05
    done

  ) | dialog --backtitle "$BACKTITLE" --title "Extraction" --mixedgauge "Progression de l'extraction" 15 70 0 2>&1 >/dev/tty

  dialog --backtitle "$BACKTITLE" --infobox "Restauration des fichiers de configuration..." 5 40 2>&1 >/dev/tty
  sleep 1

  for BOOTFILE in ${BOOTFILES}; do
    if [ -e "/boot/${BOOTFILE}.upgrade" ]; then
      mv "/boot/${BOOTFILE}.upgrade" "/boot/${BOOTFILE}" || echo "Erreur restauration $BOOTFILE" >&2
    fi
  done

  dialog --backtitle "$BACKTITLE" --infobox "Remontée de /boot en lecture seule..." 5 40 2>&1 >/dev/tty
  sleep 1
  mount -o remount,ro /boot || exit 1

  # Supprimer l’archive téléchargée
  rm -f "$DEST_FILE"

  dialog --backtitle "$BACKTITLE" --title "Terminé" --msgbox "Mise à jour terminée avec succès !" 6 40 2>&1 >/dev/tty

  dialog --backtitle "$BACKTITLE" \
    --title "Redémarrage nécessaire" \
    --yesno "Un redémarrage de Batocera est nécessaire.\n\nVoulez-vous redémarrer maintenant ?" 8 50 2>&1 >/dev/tty

  reponse=$?
  clear
  if [ "$reponse" -eq 0 ]; then
    reboot
  else
    echo "Redémarrage annulé. Pensez à redémarrer manuellement plus tard."
    exit 0
  fi
}

# Main
verifier_connexion
selectionner_version
verifier_espace
confirmer_version
telecharger_fichier
extraire_et_mettre_a_jour
