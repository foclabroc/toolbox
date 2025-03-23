#!/bin/bash

# Fonction pour afficher un message pendant 2 secondes
show_message() {
  dialog --msgbox "$1" 6 50
  sleep 2
}

tools_options() {
  show_message() {
    dialog --msgbox "$1" 6 50
  }

# Fonction pour exécuter l'enregistrement avec sous-menu
  start_recording_menu() {
    CHOICE=$(dialog --menu "Choisissez une option d'enregistrement" 15 60 4 \
      1 "Record manuel (avec bouton Stop)" \
      2 "Record 15 secondes (arrêt auto)" \
      3 "Record 35 secondes (arrêt auto)" \
      4 "Retour" \
      2>&1 >/dev/tty)

    case $CHOICE in
      1)
        start_recording_manual
        ;;
      2)
        start_recording_auto 15
        ;;
      3)
        start_recording_auto 35
        ;;
      4)
        return
        ;;
    esac
  }

  # Fonction pour l'enregistrement manuel
  start_recording_manual() {
    if [ -f /tmp/record_pid ]; then
      show_message "Un enregistrement est déjà en cours."
      return
    fi

    tmux new-session -d -s record_session "bash -c 'batocera-record'"
    RECORD_PID=$(pgrep -f "batocera-record" | head -n 1)
    echo $RECORD_PID > /tmp/record_pid

    CHOICE=$(dialog --title "Capture vidéo" --backtitle "Foclabroc Toolbox" \
      --no-items --stdout \
      --menu "Capture vidéo en cours. Appuyez sur Stop pour terminer..." 15 60 1 \
      "Stop Capture")

    if [ "$CHOICE" == "Stop Capture" ]; then
      stop_recording
    fi
  }

  # Fonction pour l'enregistrement automatique avec arrêt après X secondes
  start_recording_auto() {
    DURATION=$1
    if [ -f /tmp/record_pid ]; then
      show_message "Un enregistrement est déjà en cours."
      return
    fi

    tmux new-session -d -s record_session "bash -c 'batocera-record'"
    RECORD_PID=$(pgrep -f "batocera-record" | head -n 1)
    echo $RECORD_PID > /tmp/record_pid

    dialog --infobox "Capture de $DURATION secondes en cours. Veuillez patienter..." 6 50
    sleep $DURATION
    stop_recording
  }

  # Fonction pour arrêter l'enregistrement
  stop_recording() {
    if tmux has-session -t record_session 2>/dev/null; then
      tmux send-keys -t record_session C-c
      sleep 2 #pour eviter la corruption de la capture
      tmux kill-session -t record_session 2>/dev/null
      rm /tmp/record_pid
      show_message "Capture vidéo enregistrée avec succès."
    else
      show_message "Aucun enregistrement en cours."
    fi
  }

  # Fonction pour afficher le menu principal
  main_menu() {
    while true; do
      CHOICE=$(dialog --menu "Choisissez une option" 15 80 4 \
        1 "[Screenshot] -> Prendre des captures d'écran de Batocera." \
        2 "[Reload]     -> Actualiser la liste des jeux." \
        3 "[Record]     -> Capturer des vidéos de l'écran de Batocera" \
        4 "[Retour]     -> Retour au menu principal de la toolbox" \
        2>&1 >/dev/tty)

      case $CHOICE in
        1)
          # Option Screenshot
          batocera-screenshot
          show_message "Screenshot enregistré dans le dossier Screenshots avec succès."
          ;;
        2)
          # Option Reload
          curl http://127.0.0.1:1234/reloadgames
          show_message "Liste des jeux actualisée avec succès."
          ;;
        3)
          # Option Record
          start_recording_menu
          ;;
        4)
          # Retour
          break
		  clear
          ;;
        *)
          # Quitter
          break
          clear
          ;;
      esac
    done
  }
  clear
  main_menu
}

# Appel de la fonction pour afficher le menu principal
tools_options
