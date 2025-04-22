#!/bin/bash

clear

show_info() {
dialog --backtitle "Foclabroc Toolbox" --title "Foclabroc Toolbox" --msgbox \
"\nBienvenue dans ma Toolbox !\n\n
Elle regroupe un ensemble de scripts conçus pour vous faciliter l'installation de mes différents packs (Switch, Kodi, NES 3D, etc.).\n\n
Vous y trouverez aussi plusieurs outils pratiques, comme le téléchargement et la gestion de vos bouteilles et Runners Wine.\n
Une section \"Tools\" est également disponible, avec des fonctionnalités comme la prise de screenshots et la capture vidéo sur Batocera (disponible uniquement en lançant la Toolbox via SSH).\n\n
Mais aussi une section \"Télechargement de jeux windows\" dans laquelle vous trouverez différents jeux Windows, majoritairement FanGame, avec ajout des médias à votre gamelist automatique.\n\n
Cerise sur le gâteau : vous pouvez aussi installer la Toolbox dans la section \"Ports\" de Batocera Linux pour y accéder directement à la manette.\n\n
Je continuerai sûrement à l’enrichir avec de nouvelles fonctionnalités au fil du temps.\n
\n
LA BISE." 30 70 2>&1 >/dev/tty
}

# Vérification de la connexion Internet
check_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        dialog --backtitle "Foclabroc Toolbox" --title "Erreur" --msgbox "\nPas de connexion Internet !" 6 40 2>&1 >/dev/tty
        exit 1
    fi
}

# Vérification de l'architecture
arch_check() {
    ARCH=$(uname -m)
    clear
    if [ "$ARCH" != "x86_64" ]; then
        dialog --backtitle "FOCLABROC TOOLBOX SCRIPT FOR BATOCERA" --title "Architecture $ARCH Détectée" --msgbox "\nArchitecture $ARCH Détectée.\nCe script ne peut être exécuté que sur des PC x86_64 (AMD/Intel)." 9 50 2>&1 >/dev/tty
        killall -9 xterm
        exit 1
    fi
}

tools_options() {
  show_message() {
    dialog --backtitle "Foclabroc Toolbox" --msgbox "$1" 7 50 2>&1 >/dev/tty
  }

# Fonction pour exécuter l'enregistrement avec sous-menu
  start_recording_menu() {
    CHOICE=$(dialog --backtitle "Foclabroc Toolbox" --menu "\nChoisissez une option d'enregistrement :\n " 15 60 4 \
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
      show_message "\nUn enregistrement est déjà en cours."
      return
    fi

    tmux new-session -d -s record_session "bash -c 'batocera-record'"
    RECORD_PID=$(pgrep -f "batocera-record" | head -n 1)
    echo $RECORD_PID > /tmp/record_pid

    CHOICE=$(dialog --title "Capture vidéo" --backtitle "Foclabroc Toolbox" \
      --no-items --stdout \
      --menu "\nCapture vidéo en cours. Appuyez sur Stop pour terminer...\n " 10 60 1 \
      "Stop Capture")

    if [ "$CHOICE" == "Stop Capture" ]; then
      stop_recording
    fi
  }

  # Fonction pour l'enregistrement automatique avec arrêt après X secondes
  start_recording_auto() {
    DURATION=$1
    if [ -f /tmp/record_pid ]; then
      show_message "\nUn enregistrement est déjà en cours."
      return
    fi

    tmux new-session -d -s record_session "bash -c 'batocera-record'"
    RECORD_PID=$(pgrep -f "batocera-record" | head -n 1)
    echo $RECORD_PID > /tmp/record_pid

    dialog --infobox "\nCapture de $DURATION secondes en cours. Veuillez patienter..." 6 50 2>&1 >/dev/tty
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
      show_message "\nCapture vidéo enregistrée avec succès.\n"
    else
      show_message "\nAucun enregistrement en cours.\n"
    fi
    start_recording_menu  # Retour automatique au sous-menu d'enregistrement
  }

# Fonction pour afficher les infos systeme
show_batocera_info() {
    echo "" > /tmp/batocera_info.txt
    batocera-info >> /tmp/batocera_info.txt
    dialog --title "Information Système" --backtitle "Foclabroc Toolbox" --textbox /tmp/batocera_info.txt 21 45 2>&1 >/dev/tty
    rm /tmp/batocera_info.txt
}

  # Fonction pour afficher le menu principal
  main_menu() {
    while true; do
      CHOICE=$(dialog --title "Menu des outils" --backtitle "Foclabroc Toolbox" --menu "\nChoisissez une option :\n " 15 80 4 \
        1 "[Infos]      -> Afficher les informations système de Batocera." \
        2 "[Retour]     -> Retour au menu principal de la toolbox" \
        2>&1 >/dev/tty)

      case $CHOICE in
        1)
          # Option Info systeme
          show_batocera_info
          ;;
        2)
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

  main_menu
}

# Confirmation d'installation
confirm_install() {
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "\nVoulez-vous vraiment installer $1 ?" 7 60 2>&1 >/dev/tty
    return $?
}

# Fonction pour afficher le menu principal
main_menu() {
    while true; do
        main_menu=$(dialog --clear --backtitle "Foclabroc Toolbox" \
            --title "Menu Principal" \
            --menu "\nSélectionnez une option :\n " 22 100 11 \
            1 "[Nintendo Switch] -> Installer l'émulation Switch sur Batocera" \
            2 "[Youtube TV]      -> Installer Youtube TV" \
            3 "[Gparted]         -> Installer Gparted" \
            4 "[Pack Kodi]       -> Installer le pack streaming/iptv kodi" \
            5 "[Pack Nes3D]      -> Installer le pack Nintendo Nes 3D" \
            6 "[Pack OpenLara]   -> Installer le pack OpenLara" \
            7 "[Pack Music]      -> Installer le pack Music pour ES" \
            8 "[Jeux Pc]         -> Téléchargement de Jeux Windows et linux..." \
            9 "[Wine Toolbox]    -> Téléchargement de Runner Wine et outils wsquash..." \
            10 "[Tools]           -> Outils pour Batocera version light. (Plus d'options dispo via ssh)" \
            11 "[Exit]            -> Quitter le script" \
            2>&1 >/dev/tty)
        clear

        case $main_menu in
            1)
                confirm_install "Nintendo Switch" || continue
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls bit.ly/foclabroc-switch-all | bash" 
                ;;
            2)
                confirm_install "Youtube TV" || continue
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/youtubetv.sh | bash" 
                ;;
            3)
                confirm_install "Gparted" || continue
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/gparted/gparted.sh | bash" 
                ;;
            4)
                confirm_install "Pack Kodi" || continue
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/kodi/pack_kodi.sh | bash"
                ;;
            5)
                confirm_install "Pack Nes 3D" || continue
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/3d/pack_3d.sh | bash"
                ;;
            6)  #Pack openlara
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/openlara/pack_lara.sh | bash"
                ;;
            7)  #Pack Music
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/music/music.sh | bash"
                ;;
            8)  #Jeux windows et linux
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/windows/_win-game.sh | bash"
                ;;
            9)  #wine tools
                clear
                DISPLAY=:0.0 xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -Ls curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/wine-tools/wine.sh | bash"
                ;;
            10)  #record tools
                clear
                tools_options
                ;;
            11)# Afficher un message de remerciement
                dialog --backtitle "Foclabroc Toolbox" --title "Quitter" --msgbox "\nMerci d'avoir utilisé le script !" 7 40 2>&1 >/dev/tty
                killall -9 xterm
                clear
                exit 0
                ;;
            *)
                dialog --backtitle "Foclabroc Toolbox" --title "Quitter" --msgbox "\nMerci d'avoir utilisé le script !" 7 40 2>&1 >/dev/tty
                killall -9 xterm
                clear
                exit 0
                ;;
        esac
    done
}

# Lancer les vérifications et afficher le menu
show_info
arch_check
check_internet
main_menu
