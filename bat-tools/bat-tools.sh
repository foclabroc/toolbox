#!/bin/bash

# Fonction pour afficher un message pendant 2 secondes
show_message() {
  dialog --msgbox "$1" 6 50
  sleep 2
}

# Vérification si `dialog` est installé
if ! command -v dialog &>/dev/null; then
  echo "Le programme 'dialog' n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
  exit 1
fi

# Fonction pour exécuter l'enregistrement
start_recording() {
  # Vérifier si un enregistrement est déjà en cours
  if pgrep -x "batocera-record" > /dev/null; then
    show_message "Un enregistrement est déjà en cours."
    return
  fi

  # Lancer batocera-record en arrière-plan
  batocera-record &
  RECORD_PID=$!

  # Afficher la fenêtre de capture en cours
  while true; do
    CHOICE=$(dialog --title "Capture en cours" --backtitle "Batocera" \
      --no-items --stdout \
      --menu "Capture en cours, appuyer sur Stop pour arrêter la capture" 15 50 1 \
      "Stop")

    case $CHOICE in
      1)
        # Envoyer le signal SIGINT pour arrêter l'enregistrement
        kill -SIGINT $RECORD_PID
        break
        ;;
    esac
  done

  # Afficher le message de fin
  show_message "Enregistrement arrêté."
}

# Fonction pour afficher le menu principal
main_menu() {
  while true; do
    CHOICE=$(dialog --menu "Choisissez une option" 15 50 5 \
      1 "Screenshot" \
      2 "Reload" \
      3 "Record" \
      4 "Retour" \
      2>&1 >/dev/tty)

    case $CHOICE in
      1)
        # Option Screenshot
        batocera-screenshot
        show_message "Screenshot enregistré dans le dossier screenshot"
        ;;
      2)
        # Option Reload
        curl http://127.0.0.1:1234/reloadgames
        show_message "Liste des jeux actualisée avec succès"
        ;;
      3)
        # Option Record
        RECORD_CHOICE=$(dialog --title "Enregistrement" --backtitle "Batocera" \
          --no-items --stdout \
          --menu "Choisir l'option" 15 50 1 \
          1 "Start Recording")

        case $RECORD_CHOICE in
          1)
            # Démarrer l'enregistrement
            start_recording
            ;;
          *)
            break
            ;;
        esac
        ;;
      4)
        # Retour
        break
        ;;
      *)
        # Quitter
        break
        ;;
    esac
  done
}

# Appel de la fonction pour afficher le menu principal
main_menu
