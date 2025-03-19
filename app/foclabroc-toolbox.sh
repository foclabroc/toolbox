#!/bin/bash

# Vérification de la connexion Internet
check_internet() {
    if ! ping -c 1 8.8.8.8 &>/dev/null; then
        dialog --title "Erreur" --msgbox "Pas de connexion Internet !" 6 40
        exit 1
    fi
}

# Affichage ASCII (poupipou)
show_ascii() {
    dialog --title "Poupipou" --msgbox "\n  ██████╗  ██████╗ ██╗   ██╗██████╗ ██╗██████╗ \n  ██╔══██╗██╔═══██╗██║   ██║██╔══██╗██║██╔══██╗\n  ██║  ██║██║   ██║██║   ██║██████╔╝██║██║  ██║\n  ██║  ██║██║   ██║██║   ██║██╔══██╗██║██║  ██║\n  ██████╔╝╚██████╔╝╚██████╔╝██║  ██║██║██████╔╝\n  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝ \n" 10 50
    sleep 3
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
            1) echo "Installation APP1...";;
            2) echo "Installation APP2...";;
            3) tools_menu;;
            4) clear; exit 0;;
        esac
    done
}

# Exécution du script
check_internet
show_ascii
main_menu

