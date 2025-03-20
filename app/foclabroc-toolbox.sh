#!/bin/bash

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
sleep 4
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
    if [ "$ARCH" = "aarch64" ]; then
        dialog --backtitle "FOCLABROC TOOLBOX SCRIPT FOR BATOCERA" --title "Architecture ARM64 Détectée" --msgbox "Architecture ARM64 (aarch64) détectée.\nCe script ne peut être exécuté que sur des PC x86_64 (AMD/Intel)." 8 50
        killall -9 xterm
        exit 1
    fi
}

#Set color
GREEN='\033[0;32m'  # Green color code
CYAN='\033[0;36m'   # Cyan color code
RED='\033[0;31m'   # Red color code
NC='\033[0m'        # Reset color code

# Confirmation d'installation
confirm_install() {
    dialog --title "Confirmation" --yesno "Voulez-vous vraiment installer $1 ?" 7 50
    return $?
}

# Fonction pour afficher le menu principal
main_menu() {
    while true; do
        OPTIONS=("1" "Nintendo Switch"
                 "2" "Standalone Apps (mostly appimages)"
                 "3" "Docker & Containers"
                 "4" "Tools"
                 "5" "Wine Custom Downloader v40+"
                 "6" "Flatpak Linux Games"
                 "7" "Other Linux & Windows/Wine Freeware games"
                 "8" "Install Portmaster"
                 "9" "Install This Menu to Ports"              
                 "10" "Exit")

        main_menu=$(dialog --clear --backtitle "Foclabroc Toolbox" \
                        --title "Main Menu" \
                        --menu "Choose an option:" 20 80 10 \
                        "${OPTIONS[@]}" \
                        2>&1 >/dev/tty)
        clear

        case $main_menu in
            1)
                # confirm_install "Nintendo Switch" || continue
                # curl -Ls curl -L bit.ly/foclabroc-switch-all | bash
                # ;;
                confirm_install "Nintendo Switch" || continue
                xterm -fs 12 -maximized -fg white -bg black -fa "DejaVuSansMono" -en UTF-8 -e bash -c "DISPLAY=:0.0  curl -L bit.ly/foclabroc-switch-all | bash" 
                ;;
            2)
                confirm_install "Apps Menu" || continue
                wget -q --tries=30 --no-check-certificate -O /tmp/runner https://github.com/trashbus99/profork/raw/master/app/appmenu.sh && chmod +x /tmp/runner && DISPLAY=:0.0 xterm -hold -bg black -fa "DejaVuSansMono" -fs 12 -en UTF-8 -e "bash /tmp/runner.sh" 
                ;;
            3)
                confirm_install "Docker Menu" || continue
                wget -q --tries=30 --no-check-certificate -O /tmp/runner https://github.com/trashbus99/profork/raw/master/app/dockermenu.sh && chmod +x /tmp/runner && bash /tmp/runner
                ;;
            4)
                confirm_install "Tools Menu" || continue
                wget -q --tries=30 --no-check-certificate -O /tmp/runner https://github.com/trashbus99/profork/raw/master/app/tools.sh && chmod +x /tmp/runner && bash /tmp/runner
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
                wget -q --tries=30 --no-check-certificate -O /tmp/runner https://github.com/trashbus99/profork/raw/master/app/install.sh && chmod +x /tmp/runner && bash /tmp/runner
                ;;
            10)
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
