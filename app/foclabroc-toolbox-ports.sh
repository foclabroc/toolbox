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
        dialog --title "Erreur" --msgbox "Pas de connexion Internet !" 6 40
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

tools_options() {
  show_message() {
    dialog --msgbox "$1" 6 50
  }

  # Fonction pour exécuter l'enregistrement
  start_recording() {
    # Vérifier si un enregistrement est déjà en cours
    if [ -f /tmp/record_pid ]; then
      show_message "Un enregistrement est déjà en cours."
      return
    fi

    # Lancer batocera-record dans une session tmux distincte
    tmux new-session -d -s record_session "bash -c 'batocera-record'"

    # Récupérer le PID du processus en cours
    RECORD_PID=$(pgrep -f "batocera-record" | head -n 1)
    echo $RECORD_PID > /tmp/record_pid

    # Afficher la fenêtre avec un bouton Stop
    CHOICE=$(dialog --title "Capture vidéo" --backtitle "Foclabroc Toolbox" \
      --no-items --stdout \
      --menu "Capture vidéo en cours. Appuyez sur stop pour terminer..." 15 60 1 \
      "Stop Capture")

    echo "CHOICE sélectionné : $CHOICE" >> /tmp/debug_record.log  # Debugging

    case $CHOICE in
      "Stop Capture")
        # Vérifier si la session tmux existe
        if tmux has-session -t record_session 2>/dev/null; then
          echo "Session tmux détectée, envoi du Ctrl+C..." >> /tmp/debug_record.log

          # Envoyer un vrai Ctrl+C
          tmux send-keys -t record_session C-c

          # Fermer la session
          tmux kill-session -t record_session 2>/dev/null
          echo "Session tmux terminée." >> /tmp/debug_record.log

          # Afficher un message de confirmation
          show_message "Capture vidéo arrêtée et enregistrée dans le dossier Recordings avec succès."
          rm /tmp/record_pid
        else
          echo "Aucune session tmux trouvée." >> /tmp/debug_record.log
          show_message "Aucun enregistrement en cours."
        fi
        ;;
      *)
        echo "CHOICE non reconnu : $CHOICE" >> /tmp/debug_record.log
        ;;
    esac
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

  main_menu
}

# Confirmation d'installation
confirm_install() {
    dialog --title "Confirmation" --yesno "Voulez-vous vraiment installer $1 ?" 7 50
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
            9 "Exit -> Quitter le script" \
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
                # Afficher un message de remerciement
                dialog --title "Quitter" --msgbox "Merci d'avoir utilisé le script !" 6 40
                killall -9 xterm
                clear
                exit 0
                ;;
            *)
                dialog --title "Quitter" --msgbox "Merci d'avoir utilisé le script !" 6 40
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
