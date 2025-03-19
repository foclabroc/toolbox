#!/bin/bash

# Vérification de la connexion Internet
check_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        dialog --title "Erreur" --msgbox "Pas de connexion Internet !" 6 40
        exit 1
    fi
}

# Vérification de l'architecture
arch_check() {
# Detect system architecture
ARCH=$(uname -m)

# Clear the screen
clear

# If the system is ARM64 (aarch64), exit the script with a dialog
if [ "$ARCH" = "aarch64" ]; then
    dialog --title "Architecture ARM64 Détectée" --msgbox "L'architecture ARM64 (aarch64) a été détectée.\nCe script ne peut être exécuté que sur des PC x86_64 (AMD/Intel)." 8 50
    killall -9 xterm
    clear
    exit 0
fi

# If the system is x86_64 continue
if [ "$ARCH" = "x86_64" ]; then
    clear
fi
}

# Affichage ASCII Title
show_ascii() {
dialog --title "FOCLABROC TOOLBOX SCRIPT FOR BATOCERA" \
       --infobox "\
###############################################\n\
#                                             #\n\
#    FOCLABROC TOOLBOX SCRIPT FOR BATOCERA    #\n\
#              [PC X86_64 ONLY]               #\n\
#                                             #\n\
###############################################" 8 51
sleep 4
clear
}

# Confirmer l'installation
confirm_install() {
    local app_name=$1
    dialog --title "Confirmation" --yesno "Voulez-vous installer $app_name ?" 7 50
    return $?
}

# Menu TOOLS
tools_menu() {
    while true; do
        CHOICE=$(dialog --title "TOOLS" --menu "Choisissez un outil:" 15 50 4 \
            1 "SCREENSHOT" \
            2 "RECORD" \
            3 "RELOAD" \
            4 "RETOUR" \
            3>&1 1>&2 2>&3)
        case "$CHOICE" in
            1) batocera-screenshot;;
            2) batocera-record;;
            3) curl http://127.0.0.1:1234/reloadgames;;
            4) return;;
        esac
    done
}

# Menu Principal
main_menu() {
    while true; do
        CHOICE=$(dialog --title "Installation d'applications" --menu "Choisissez une action:" 15 50 6 \
            1 "Installer APP1" \
            2 "Installer APP2" \
            3 "TOOLS" \
            4 "QUITTER" \
            3>&1 1>&2 2>&3)
        case "$CHOICE" in
            1)
                if confirm_install "APP1"; then
                    echo "Installation de APP1..."
                    # Ajoute ici la commande réelle d'installation de APP1
                else
                    echo "Installation de APP1 annulée."
                fi
                ;;
            2)
                if confirm_install "APP2"; then
                    echo "Installation de APP2..."
                    # Ajoute ici la commande réelle d'installation de APP2
                else
                    echo "Installation de APP2 annulée."
                fi
                ;;
            3) tools_menu;;
            4)
                # Afficher un message de remerciement
                dialog --title "Merci" --msgbox "Merci d'avoir utilisé le script !" 6 40
                killall -9 xterm
                clear
                exit 0
                ;;
        esac
    done
}

# Exécution du script
arch_check
check_internet
show_ascii
main_menu