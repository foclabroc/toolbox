#!/bin/bash

# Fonction pour afficher un message pendant 2 secondes
show_message() {
  dialog --msgbox "$1" 6 50
  sleep 2
}

# Fonction pour exécuter l'enregistrement
start_recording() {
  # Lancer batocera-record en arrière-plan
  batocera-record &>/dev/null &
  RECORD_PID=$(pgrep -o batocera-record)

  # Attendre un peu pour que le processus démarre
  sleep 1  # Ajuste si nécessaire

  # Afficher la fenêtre avec un bouton Stop
  CHOICE=$(dialog --title "Capture vidéo" --backtitle "Foclabroc Toolbox" \
    --no-items --stdout \
    --menu "Capture vidéo en cours appuyez sur stop pour terminer..." 15 60 1 \
    "Stop Capture")

  case $CHOICE in
    1)
      # Trouver la fenêtre du terminal qui contient batocera-record et envoyer ctrl+c
      WINDOW_ID=$(xdotool search --name "batocera-record" | head -n 1)
      xdotool windowactivate --sync $WINDOW_ID key ctrl+c
      ;;
  esac

  # Afficher le message de fin
  show_message "Capture vidéo enregistée dans le dossier Recordings avec succès."
}

# Fonction pour afficher le menu principal
main_menu() {
  while true; do
    CHOICE=$(dialog --menu "Choisissez une option" 15 80 4 \
      1 "[Screenshot] -> Prendre des captures d'ecran de Batocera." \
      2 "[Reload]     -> Actualiser la liste des jeux." \
      3 "[Record]     -> Capturer des vidéos de l'ecran de batocera" \
      4 "[Retour]     -> Retour au menu principal de la toolbox" \
      2>&1 >/dev/tty)

    case $CHOICE in
      1)
        # Option Screenshot
        batocera-screenshot
        show_message "Screenshot enregistré dans le dossier Screenshots avec succès"
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
