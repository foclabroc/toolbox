#!/bin/bash

while true; do
    choix=$(dialog --clear --title "Menu Principal" --menu "Choisissez une option :" 15 50 6 \
        1 "Installer Application 1" \
        2 "Installer Application 2" \
        TOOLS "Outils" \
        QUITTER "Quitter" \
        2>&1 >/dev/tty)

    case "$choix" in
        1|2)
            dialog --yesno "Voulez-vous vraiment installer l'application $choix ?" 7 50
            if [ $? -eq 0 ]; then
                echo "Installation de l'application $choix en cours..."
                sleep 2  # Simulation d'installation
            else
                dialog --msgbox "Installation annulée." 5 30
            fi
            ;;
        TOOLS)
            while true; do
                tool_choice=$(dialog --clear --title "Outils" --menu "Sélectionnez un outil :" 15 50 4 \
                    SCREENSHOT "Prendre une capture d'écran" \
                    RECORD "Enregistrer une vidéo" \
                    RELOAD "Recharger les jeux" \
                    RETOUR "Retour" \
                    2>&1 >/dev/tty)

                case "$tool_choice" in
                    SCREENSHOT) batocera-screenshot ;;
                    RECORD) batocera-record ;;
                    RELOAD) curl http://127.0.0.1:1234/reloadgames ;;
                    RETOUR) break ;;
                esac
            done
            ;;
        QUITTER)
            dialog --msgbox "Merci d'avoir utilisé le script !" 6 40
            killall -9 xterm
            clear
            exit 0
            ;;
    esac
done