#!/bin/bash

clear

show_ascii() {
echo -e "\e[1;36m"
echo ""
echo "     #####################################################################################################################"
echo "     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@        @@        ,@@@/        &@@     @@@@@&       @@@          @@@         &@@@         @@@&        /@@@@@@@#"
echo "     #@@@@@     ...@     @     @.    @/    &@     @@@@@        @@@     @     @@     %    @@     @     @#    (&    (@@@@@@#"
echo "     #@@@@@     @@@@     @     @     @/    (@     @@@@@    (    @@     @     @@     &    @@     @     @*    #&    .@@@@@@#"
echo "     #@@@@@       (@     @     @     @@@@@@@@     @@@@@    @    @@          @@@        ,@@@     @     @*    #@@@@@@@@@@@@#"
echo "     #@@@@@     @@@@     @     @     @/    (@     @@@@     ,    %@     @     @@     @    @@     @     @*    #&    .@@@@@@#"
echo "     #@@@@@     @@@@     @     @,    @/    &@     @@@@           @     @     @@     @    &@     @     @%    #&    /@@@@@@#"
echo "     #@@@@@     @@@@@         @@@         *@@        @     @     @           @@     @    &@@         @@@          @@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@.          @,         @@@         @@@     @@@%         .@@@         @@     @    @@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@@    .%    /@     @     @@     @@@%    ,%    @@     @     @@        (@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%    .     @@     @     @@        @@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%          @@     @     @@        @@@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%    ,&    .@     @     @@         @@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@@    .#    %@     @     @@       /%    ,.    .@     @     @,    @    @@@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@     @@@@@        @@@@/        @@@       /%          @@@/       .@@     @     @@@@@@@@@@@@@@@@@@#"
echo "     #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "     #####################################################################################################################"
echo ""
echo "                                     ###############################################"
echo "                                     #                                             #"
echo "                                     #    FOCLABROC TOOLBOX SCRIPT FOR BATOCERA    #"
echo "                                     #              [PC X86_64 ONLY]               #"
echo "                                     #                                             #"
echo "                                     ###############################################"
echo -e "\e[0m"
sleep 3
}

# Vérification de la connexion Internet
check_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        dialog --backtitle "Foclabroc Toolbox" --title "Erreur" --msgbox "Pas de connexion Internet !" 6 40
        exit 1
    fi
}

# Vérification de l'architecture
arch_check() {
    ARCH=$(uname -m)
    clear
    if [ "$ARCH" != "x86_64" ]; then
        dialog --backtitle "FOCLABROC TOOLBOX SCRIPT FOR BATOCERA" --title "Architecture $ARCH Détectée" --msgbox "\nArchitecture $ARCH Détectée.\nCe script ne peut être exécuté que sur des PC x86_64 (AMD/Intel)." 9 50
        killall -9 xterm
        exit 1
    fi
}
# Fonction pour le sous-menu Tools
tools_options() {
  show_message() {
    dialog --backtitle "Foclabroc Toolbox" --msgbox "$1" 7 50
  }

  # Fonction pour exécuter l'enregistrement avec sous-menu
  start_recording_menu() {
    CHOICE=$(dialog --title "Menu Enregistrement" --backtitle "Foclabroc Toolbox" --menu "\nChoisissez une option d'enregistrement :\n " 15 60 4 \
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

    dialog --infobox "\nCapture de $DURATION secondes en cours. Veuillez patienter..." 6 50
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
    dialog --title "Information Système" --backtitle "Foclabroc Toolbox" --textbox /tmp/batocera_info.txt 18 60
    rm /tmp/batocera_info.txt
}

  # Fonction pour afficher le menu principal
  main_menu() {
    while true; do
      CHOICE=$(dialog --title "Menu des outils" --backtitle "Foclabroc Toolbox" --menu "\nChoisissez une option :\n " 15 80 4 \
        1 "[Screenshot] -> Prendre des captures d'écran de Batocera." \
        2 "[Reload]     -> Actualiser la liste des jeux." \
        3 "[Record]     -> Capturer des vidéos de l'écran de Batocera" \
        4 "[Infos]      -> Afficher les informations système de Batocera." \
        5 "[Retour]     -> Retour au menu principal de la toolbox" \
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
          show_message "\nListe des jeux actualisée avec succès."
          ;;
        3)
          # Option Record
          start_recording_menu
          ;;
        4)
          # Option Info systeme
          show_batocera_info
          ;;
        5)
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
    dialog --backtitle "Foclabroc Toolbox" --title "Confirmation" --yesno "Voulez-vous vraiment installer $1 ?" 7 50
    return $?
}

# Fonction pour afficher le menu principal
main_menu() {
    while true; do
        main_menu=$(dialog --clear --backtitle "Foclabroc Toolbox" \
            --title "Menu Principal" \
            --menu "\nSélectionnez une option :\n " 25 85 10 \
            1 "[Nintendo Switch] -> Installer l'émulation Switch sur Batocera" \
            2 "[Youtube TV]      -> Installer Youtube TV" \
            3 "[Gparted]         -> Installer Gparted" \
            4 "[Tools]           -> Outils pour Batocera. Screenshot, Records..." \
            5 "Wine Custom -> Télécharge une version optimisée de Wine" \
            6 "Flatpak Linux Games -> Installe des jeux Linux via Flatpak" \
            7 "Other Freeware Games -> Jeux Linux & Windows (Wine)" \
            8 "Install Portmaster -> Gestionnaire de ports pour Batocera" \
            9 "Install This Menu to Ports -> Ajoute ce menu aux ports Batocera" \
            10 "Exit -> Quitter le script" \
            2>&1 >/dev/tty)
        clear

        case $main_menu in
            1)
                confirm_install "Nintendo Switch" || continue
                clear
                curl -Ls bit.ly/foclabroc-switch-all | bash
                ;;
            2)
                confirm_install "Youtube TV" || continue
                clear
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/youtubetv.sh | bash
                ;;
            3)
                confirm_install "Gparted" || continue
                clear
                curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/gparted/gparted.sh | bash
                ;;
            4)
                clear
                tools_options
                ;;
            5)
                confirm_install "Wine Custom" || continue
                curl -Ls https://github.com/trashbus99/profork/raw/master/wine-custom/wine.sh | bash
                ;;
            6)
                confirm_install "Flatpak Linux Games" || continue
                curl -Ls https://raw.githubusercontent.com/trashbus99/profork/master/app/fpg.sh | bash
                ;;
            7)
                confirm_install "Other Linux & Windows/Wine Freeware" || continue
                curl -Ls https://github.com/trashbus99/profork/raw/master/app/wquashfs.sh | bash
                ;;
            8)
                confirm_install "Portmaster Installer" || continue
                curl -Ls https://github.com/trashbus99/profork/raw/master/portmaster/install.sh | bash
                ;;
            9)
                confirm_install "Ports Installer" || continue 
                clear
                wget -q --tries=30 --no-check-certificate -O /tmp/runner https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/install-to-port.sh && chmod +x /tmp/runner && bash /tmp/runner
                ;;
            10)
                # Afficher un message de remerciement
                dialog --backtitle "Foclabroc Toolbox" --title "Quitter" --msgbox "Merci d'avoir utilisé le script !" 7 40
                killall -9 xterm
                clear
                exit 0
                ;;
            *)
                dialog --backtitle "Foclabroc Toolbox" --title "Quitter" --msgbox "\nMerci d'avoir utilisé le script !" 7 40
                killall -9 xterm
                clear
                exit 0
                ;;
        esac
    done
}

# Lancer les vérifications et afficher le menu
show_ascii
arch_check
check_internet
main_menu
