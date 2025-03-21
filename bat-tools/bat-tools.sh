#!/bin/bash

# Fonction pour afficher un message pendant 2 secondes
show_message() {
  dialog --msgbox "$1" 6 50
  sleep 2
}

# Fonction pour exécuter l'enregistrement et afficher un chronomètre
start_recording() {
  # Lancer batocera-record en arrière-plan
  batocera-record &
  RECORD_PID=$!

  # Afficher la fenêtre de chronomètre avec un bouton Stop
  SECONDS=0
  while true; do
    # Mettre à jour le chronomètre
    MINUTES=$((SECONDS / 60))
    SECS=$((SECONDS % 60))
    TIME="$MINUTES:$SECS"

    # Afficher la fenêtre avec le chronomètre et un bouton Stop
    CHOICE=$(dialog --title "Enregistrement en cours" --backtitle "Batocera" \
      --menu "Chronomètre: $TIME" 15 50 3 \
      1 "Stop" \
      2>&1 >/dev/tty)

    case $CHOICE in
      1)
        # Envoyer le signal SIGINT pour arrêter l'enregistrement
        kill -SIGINT $RECORD_PID
        break
        ;;
    esac

    # Incrémenter le chronomètre
    sleep 1
    ((SECONDS++))
  done

  # Afficher le message de fin
  show_message "Enregistrement arrêté."
}

# Menu principal avec 3 options
while true; do
  CHOICE=$(dialog --menu "Choisissez une option" 15 50 3 \
    1 "Screenshot" \
    2 "Reload" \
    3 "Record" \
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
      start_recording
      ;;
    *)
      # Quitter
      break
      ;;
  esac
done