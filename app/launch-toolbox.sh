#!/bin/bash

# Fichier de log des erreurs
LOG_FILE="/tmp/install_errors.log"

# Fonction pour loguer les erreurs
log_error() {
    error_message=$1
    echo "$(date) - $error_message" >> "$LOG_FILE"
}

# Detect system architecture
ARCH=$(uname -m)

# If the system is ARM64 (aarch64), exit script
clear
if [ "$ARCH" = "aarch64" ]; then
    echo "ARM64 (aarch64) detected. This script only runs on PC x86_64 (AMD/Intel)...Exit"
    sleep 3
    exit 0
fi

# If the system is x86_64, continue with the normal setup
if [ "$ARCH" != "x86_64" ]; then
    echo "This script only runs on PC x86_64 (AMD/Intel)."
    exit 1
fi
echo -e "\e[1;36m"
echo ""
echo "#####################################################################################################################"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@        @@        ,@@@/        &@@     @@@@@&       @@@          @@@         &@@@         @@@&        /@@@@@@@#"
echo "#@@@@@     ...@     @     @.    @/    &@     @@@@@        @@@     @     @@     %    @@     @     @#    (&    (@@@@@@#"
echo "#@@@@@     @@@@     @     @     @/    (@     @@@@@    (    @@     @     @@     &    @@     @     @*    #&    .@@@@@@#"
echo "#@@@@@       (@     @     @     @@@@@@@@     @@@@@    @    @@          @@@        ,@@@     @     @*    #@@@@@@@@@@@@#"
echo "#@@@@@     @@@@     @     @     @/    (@     @@@@     ,    %@     @     @@     @    @@     @     @*    #&    .@@@@@@#"
echo "#@@@@@     @@@@     @     @,    @/    &@     @@@@           @     @     @@     @    &@     @     @%    #&    /@@@@@@#"
echo "#@@@@@     @@@@@         @@@         *@@        @     @     @           @@     @    &@@         @@@          @@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@.          @,         @@@         @@@     @@@%         .@@@         @@     @    @@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@@    .%    /@     @     @@     @@@%    ,%    @@     @     @@        (@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%    .     @@     @     @@        @@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%          @@     @     @@        @@@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@&    .%    *@     @     @@     @@@%    ,&    .@     @     @@         @@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@@    .#    %@     @     @@       /%    ,.    .@     @     @,    @    @@@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@     @@@@@        @@@@/        @@@       /%          @@@/       .@@     @     @@@@@@@@@@@@@@@@@@#"
echo "#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#"
echo "#####################################################################################################################"
echo ""
echo ""
echo "                     ######################################################################"
echo "                     #  PC x86_64 (AMD/INTEL) detected. Loading Foclabroc toolbox...      #"
echo "                     #  PC x86_64 (AMD/INTEL) detecté. Chargement de Foclabroc toolbox... #"
echo "                     ######################################################################"
echo -e "\e[0m"
sleep 4

# Choix de la langue
choose_language() {
    local selected=0
    local key
    while true; do
        clear
        echo -e "\e[1;36m"
        echo "######################################################"
        echo "#              CHOOSE THE SCRIPT LANGUAGE            #"
        echo "#----------------------------------------------------#"
        echo "#              CHOISIR LA LANGUE DU SCRIPT           #"
        echo "######################################################"
        echo -e "\e[0m"
        echo -e "\e[1;37m"
        echo "Use ↑ and ↓ to choose, then press Enter to confirm."
        echo "--------------------------------------------------------"
        echo "Utilisez ↑ et ↓ pour naviguer, Entrée pour sélectionner."
        echo "--------------------------------------------------------"

        if [[ $selected -eq 0 ]]; then
            echo -e "\e[1;32m>> \e[1;37m[ \e[1;34mFRANÇAIS \e[1;37m] \e[1;32m<<\e[1;37m"
            echo -e "   [ ENGLISH ]"
        else
            echo -e "   [ FRANÇAIS ]"
            echo -e "\e[1;32m>> \e[1;37m[ \e[1;31mENGLISH \e[1;37m] \e[1;32m<<\e[1;37m"
        fi

        read -rsn1 key
        case "$key" in
            $'\x1B')
                read -rsn2 -t 0.1 key
                case "$key" in
                    "[A") ((selected--)); [[ $selected -lt 0 ]] && selected=1 ;;
                    "[B") ((selected++)); [[ $selected -gt 1 ]] && selected=0 ;;
                esac
                ;;
            "") # Entrée
                if [[ $selected -eq 0 ]]; then
                    LANG="fr"
                else
                    LANG="en"
                fi
                break
                ;;
        esac
    done
}

# Déclaration du tableau associatif descriptions
declare -A descriptions

# Messages en fonction de la langue
set_messages() {
    if [[ $LANG == "fr" ]]; then
        RELOADESMSG1="Mise à jour de la liste des jeux..."
        RELOADESMSG2="Liste des jeux actualisée avec succès"
        SCREENSHOTMSG1="Capture d'écran en cours..."
        SCREENSHOTMSG2="Capture d'écran sauvegardé avec succès dans le dossier (/userdata/screenshots/)"
        DSCREENSHOT="- Prendre une capture d'écran de Batocera"
        DRELOAD="- Mettre à jour la liste des jeux"
        DESCRIPTION="Sélectionnez l'application à installer."
        INSTALL_MESSAGE="Voulez-vous installer"
        INSTALL_OF="Installation de"
        SUCCESS_MESSAGE="Installation terminée avec succès."
        FAILURE_MESSAGE="Échec de l'installation."
        EXIT_MESSAGE="Merci d'avoir utilisé le programme."
        RETRY_MESSAGE="Appuyez sur [Entrée] pour réessayer ou [Q] pour quitter."
        QUIT_OPTION="QUITTER"
        YES="OUI"
        NO="NON"
        INTERNET_CHECK="Vérification de la connexion Internet..."
        BACK="RETOUR"
        CHOOSE="Utilisez ↑ et ↓ pour choisir, puis appuyez sur Entrée pour confirmer."
        # Descriptions des applications en français
        descriptions["NINTENDO-SWITCH"]="Installer le pack Switch via le Curl de Foclabroc (Détection de version automatique)"
        descriptions["GPARTED"]="GParted est un éditeur de partition gratuit pour gérer graphiquement vos partitions de disque."
        descriptions["YOUTUBE-TV"]="Installer YoutubeTV pour Batocera (sera disponible dans [ports])."
        descriptions["MINECRAFT"]="Un jeu vidéo sandbox populaire où vous pouvez construire et explorer des mondes"
        descriptions["NETFLIX"]="Une plateforme de streaming vidéo avec un large catalogue de films et de séries"
        descriptions["STEAM"]="Une plateforme de jeu qui propose des jeux PC, des fonctions multijoueurs et bien plus"
        descriptions["POUPIPOU"]="5 secondes de bonheur"
        descriptions["TOOLS"]="Outils supplémentaires"
    else
        RELOADESMSG1="Updating gamelist..."
        RELOADESMSG2="Gamelist successfully updated"
        SCREENSHOTMSG1="Taking screenshot of batocera screen..."
        SCREENSHOTMSG2="Screenshot successfully save in (/userdata/screenshots/) folder"
        DSCREENSHOT="- Take a screenshot of Batocera screen"
        DRELOAD="- Update Batocera Gamelist"
        DESCRIPTION="Select the application to install."
        INSTALL_MESSAGE="Do you want to install"
        INSTALL_OF="Installation of"
        SUCCESS_MESSAGE="Installation completed successfully."
        FAILURE_MESSAGE="Installation failed."
        EXIT_MESSAGE="Thank you for using the program."
        RETRY_MESSAGE="Press [Enter] to retry or [Q] to quit."
        QUIT_OPTION="QUIT"
        YES="YES"
        NO="NO"
        INTERNET_CHECK="Checking the Internet connection..."
        BACK="BACK"
        CHOOSE="Use ↑ and ↓ to choose, then press Enter to confirm."
        # Descriptions des applications en anglais
        descriptions["NINTENDO-SWITCH"]="Install the Switch pack via Foclabroc Curl (Automatic version detection)"
        descriptions["GPARTED"]="GParted is a free partition editor for graphically managing your disk partitions."
        descriptions["YOUTUBE-TV"]="Install YoutubeTV for Batocera (will be available in [ports])"
        descriptions["MINECRAFT"]="A popular sandbox video game where you can build and explore worlds"
        descriptions["NETFLIX"]="A video streaming platform with a wide range of movies and TV shows"
        descriptions["STEAM"]="A gaming platform offering PC games, multiplayer features, and more"
        descriptions["POUPIPOU"]="5 seconds of happiness"
        descriptions["TOOLS"]="Additional tools"
    fi
}

# Fonction pour afficher le titre
display_title() {
    echo -e "\e[1;36m"
    echo "###############################################"
    echo "#                                             #"
    echo "#    FOCLABROC TOOLBOX SCRIPT FOR BATOCERA    #"
    echo "#              [PC X86_64 ONLY]               #"
    echo "#                                             #"
    echo "###############################################"
    echo -e "\e[0m"
}

# Vérification de la connexion Internet
check_internet() {
    curl -s --head http://www.google.com | grep "200 OK" > /dev/null
    if [[ $? -ne 0 ]]; then
        echo "Pas de connexion Internet. No internet connexion."
        exit 1
    fi
}

# Fonction pour afficher l'art ASCII
display_ascii_art() {
    clear
    end=$((SECONDS+5))  # Durée 5 secondes

    while [ $SECONDS -lt $end ]; do
        clear
		echo -e "\e[1;36m"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(*,....,,,,,,.....,..,.,....,,,,.....           .*#@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#*,,,,.,,,.............,...,,,,,......*,..          ..,#@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@(,.,.,,*****,,..       ..,,,**,,,**,...*,.,,..            .(@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@#,,...,****/(//////**..    .,,.,,,,*......,,.,,.              ,/&@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@(..,,,*//((///(((((#(((/*,,....,,*,**,,, .,,,.....              ./%@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@/,.,,,*/(/(//((##%%%%%&%%%%##(/*,,*(,/*,,,,,,,....,...             .*%@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@%*,,*//(((((((#%%%%%%%%%%&%%%&%%%#/***//,(/***,,*.,.,,. .             ,#@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@/***//##((###%%%%#%#%%%%%%%%%&&&%%&%%((/((/*,,.,,*,.,..,.,..         ...,(@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@(///(((((############%%%%%%%%&&%%%%&&&%%######(((((//**,**,,.,.     . .,..,#@@@@@@"
		echo "@@@@@@@@@@@@@@@@(/(/((((#########%####%%%%%%%%%%%%&%%%%%%%%%%#######(((////**,,,,... ....,.,(@@@@@@"
		echo "@@@@@@@@@@@@@@@((///(/(##########%%#%##%%%%%%%%%%%%%%%%%%############((((///*****,......,..,*#@@@@@"
		echo "@@@@@@@@@@@@@@%(/////(#########%#%%#%%%%%%%%%%%%%%%%%%%%#%#########(((((((////***,*,,,...,,,*%@@@@@"
		echo "@@@@@@@@@@@@@@%///**(##(#######%#(######%%%%&&&%&%%%%%%%%%#######(((((((///////******,,,,,,,*%@@@@@"
		echo "@@@@@@@#%%%%#(@%///*/((((#(###%#%%%%%%%%##%#%%%%&&%%%%%%%%%########((((/////////*********,,,,,%@@@@"
		echo "@@@@@%%//#%%%%%#(///((####%%%%%%%%%%&%&&%%%%%##%%%%%%%%%%%#%%%######((((////////*********,*,,.(@@@@"
		echo "@@@@%#*(%&&&&%%%#//((#####%#%%%%%%%###%%%%%%%%%%%%%%%%%%%%%%%%%####(((((((////*/********,***.,#@@@@"
		echo "@@@&%//#%&&&%%%%%(###%%%%#####(########(##%%%%%%%%%%%%%%%%%%%#((((#(((((//////*******,**,,**,*&@@@@"
		echo "@@@&#/#%&&&&&%#%%####%%%######(*,,,,,/(/((####%%%%%%%%%%%%%##(((((((((///***********,,,*,,***/@@@@@"
		echo "@@@&##%&%###(((%####%%%%%##((*/%%*,%% .,,///###%%%&&%%%%###((/(((((((((((((((//*****,*,*,,***(@@@@@"
		echo "@@@@%#%#((##%&&%###%%%%%%%%%#####%,*,,*,(#(###%%%%&&%%%##(/*////////((((((((((/(//**,,**,***/&@@@@@"
		echo "@@@@&#%%#((%&&%%#########%%%%%%%####(((((((#%%%%%%%%%##((*******(##(((((/((((/////*****,***/@@@@@@@"
		echo "@@@@@%##%%%%######%%#%%###%%%%%%%%###(((((######%%%%#((/*****(/*(.....,//***(////*****,,**/@@@@@@@@"
		echo "@@@@@@%%%%%&&&%##%%%%%%%%%%%%%%%%##%#%#######(######((/*****/*#%/,.  .,,/.***//*******,,*#@@@@@@@@@"
		echo "@@@@@@@%%%%%%%%##%%%%%%%%%%%%%###%%%%%%%%##########((/******/(((((/..,(/***,*********.,,,,,***#@@@@"
		echo "@@@@@@@@@%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%#######%###((/******//((((((//////**********,,*****,**/(@@"
		echo "@@@@@@@@@@%%%%##%%%%%%%%&&&%%%%%%%%%%%%%##########((/******///(((((((((/////**********,,******/(@@@"
		echo "@@@@@@@@@@@@@@@#%%%%%%%%&&&%&%%%%%%%%%%%##########((/*,,****///(((((((((((///*******..,*****,*//@@@"
		echo "@@@@@@@@@@@@@@&%%%%%%%%%&&&&&&%%%%&%%%######%%%%##((/*,,****///(((((((((((///******...,,***,*/(@@@@"
		echo "@@@@@@@@@@@@@@&#%%%%%%%%%%&&&%%%%&%%%#%%%%%%%&&%%##(/**,,,**//((((((((((((///*****....,,****/@@@@@@"
		echo "@@@@@@@@@@@@@@@#%%%%%%%%%%%%%%%%%%%%%%####(#%%%%##(/////*,**//(((((((((((////****,,,.,,,*/@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#(((/*..,/(/*,*/(((#(((((((////****,,,.,,,**&@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@%%%%%%%%####%%%%%%%%%%%%%%%%%###(((((//**///((#(###(((((///**/,,,,,,**&@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@&%%%%%%(/(%%%#%%%%%%%%%%%%%#%%%#####(((((((((#(((#(((((/////(**,**(@@@@@@@@@@@@@@@@"
		echo "@@@@@@%(((((((((%%%%%#(%%%%%%%#/##%%%%%%##%%%######(#((((((((((((((((/////%@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "&%&&%,.*/(((((((#%%%%%%%%%%%%%%%#((#(/((##%##((#((#((((((((((((((///////(@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@*(#########%%%%%%%%%%%%%%%%%%%###(((//****//((((((/(((((((////////#@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@%(%%%%%###%%%%%%%%%%%%%%%%%%%%%%%%###(((//(((((///(((###((//////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@(%%%%%%%%%%%%%%%%%%%%&%&%%%%%%%%%%%%%##((((((((((//(##((/////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@&/%%%%%%%%%%%%%%%%%%%%&%&&%%%%%%%%%%%##(((((((/////((//////...,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "&@@@@@@%(%%%%%%%%%%%%%%%%%%%%%%&&&%%%%%%%####(((((///////////*,,.... */(&@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@#/%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####(((((////////**,,,,,,,,..*/****#&@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@((%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####((/////////****,,,,,,,,.*(//////***(%@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@%(%%%%%%%%%%%%%%%%%%%%%%%#%%%###((//((((////*****,,,,,,,,*(((/(((/*////*//#&@@@@@@@@@@@@"
		echo -e "\e[0m"
		sleep 1
		
		clear
		echo -e "\e[1;31m"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(*,....,,,,,,.....,..,.,....,,,,.....           .*#@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#*,,,,.,,,.............,...,,,,,......*,..          ..,#@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@(,.,.,,*****,,..       ..,,,**,,,**,...*,.,,..            .(@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@@@#,,...,****/(//////**..    .,,.,,,,*......,,.,,.              ,/&@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@@(..,,,*//((///(((((#(((/*,,....,,*,**,,, .,,,.....              ./%@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@@@/,.,,,*/(/(//((##%%%%%&%%%%##(/*,,*(,/*,,,,,,,....,...             .*%@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@@%*,,*//(((((((#%%%%%%%%%%&%%%&%%%#/***//,(/***,,*.,.,,. .             ,#@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@@/***//##((###%%%%#%#%%%%%%%%%&&&%%&%%((/((/*,,.,,*,.,..,.,..         ...,(@@@@@@@"
		echo "@@@@@@@@@@@@@@@@@(///(((((############%%%%%%%%&&%%%%&&&%%######(((((//**,**,,.,.     . .,..,#@@@@@@"
		echo "@@@@@@@@@@@@@@@@(/(/((((#########%####%%%%%%%%%%%%&%%%%%%%%%%#######(((////**,,,,... ....,.,(@@@@@@"
		echo "@@@@@@@@@@@@@@@((///(/(##########%%#%##%%%%%%%%%%%%%%%%%%############((((///*****,......,..,*#@@@@@"
		echo "@@@@@@@@@@@@@@%(/////(#########%#%%#%%%%%%%%%%%%%%%%%%%%#%#########(((((((////***,*,,,...,,,*%@@@@@"
		echo "@@@@@@@@@@@@@@%///**(##(#######%#(######%%%%&&&%&%%%%%%%%%#######(((((((///////******,,,,,,,*%@@@@@"
		echo "@@@@@@@#%%%%#(@%///*/((((#(###%#%%%%%%%%##%#%%%%&&%%%%%%%%%########((((/////////*********,,,,,%@@@@"
		echo "@@@@@%%//#%%%%%#(///((####%%%%%%%%%%&%&&%%%%%##%%%%%%%%%%%#%%%######((((////////*********,*,,.(@@@@"
		echo "@@@@%#*(%&&&&%%%#//((#####%#%%%%%%%###%%%%%%%%%%%%%%%%%%%%%%%%%####(((((((////*/********,***.,#@@@@"
		echo "@@@&%//#%&&&%%%%%(###%%%%#####(########(##%%%%%%%%%%%%%%%%%%%#((((#(((((//////*******,**,,**,*&@@@@"
		echo "@@@&#/#%&&&&&%#%%####%%%######(*,,,,,/(/((####%%%%%%%%%%%%%##(((((((((///***********,,,*,,***/@@@@@"
		echo "@@@&##%&%###(((%####%%%%%##((*/%%*,%% .,,///###%%%&&%%%%###((/(((((((((((((((//*****,*,*,,***(@@@@@"
		echo "@@@@%#%#((##%&&%###%%%%%%%%%#####%,*,,*,(#(###%%%%&&%%%##(/*////////((((((((((/(//**,,**,***/&@@@@@"
		echo "@@@@&#%%#((%&&%%#########%%%%%%%####(((((((#%%%%%%%%%##((*******(##(((((/((((/////*****,***/@@@@@@@"
		echo "@@@@@%##%%%%######%%#%%###%%%%%%%%###(((((######%%%%#((/*****(/*(.....,//***(////*****,,**/@@@@@@@@"
		echo "@@@@@@%%%%%&&&%##%%%%%%%%%%%%%%%%##%#%#######(######((/*****/*#%/,.  .,,/.***//*******,,*#@@@@@@@@@"
		echo "@@@@@@@%%%%%%%%##%%%%%%%%%%%%%###%%%%%%%%##########((/******/(((((/..,(/***,*********.,,,,,***#@@@@"
		echo "@@@@@@@@@%%%%%%%#%%%%%%%%%%%%%%%%%%%%%%%%#######%###((/******//((((((//////**********,,*****,**/(@@"
		echo "@@@@@@@@@@%%%%##%%%%%%%%&&&%%%%%%%%%%%%%##########((/******///(((((((((/////**********,,******/(@@@"
		echo "@@@@@@@@@@@@@@@#%%%%%%%%&&&%&%%%%%%%%%%%##########((/*,,****///(((((((((((///*******..,*****,*//@@@"
		echo "@@@@@@@@@@@@@@&%%%%%%%%%&&&&&&%%%%&%%%######%%%%##((/*,,****///(((((((((((///******...,,***,*/(@@@@"
		echo "@@@@@@@@@@@@@@&#%%%%%%%%%%&&&%%%%&%%%#%%%%%%%&&%%##(/**,,,**//((((((((((((///*****....,,****/@@@@@@"
		echo "@@@@@@@@@@@@@@@#%%%%%%%%%%%%%%%%%%%%%%####(#%%%%##(/////*,**//(((((((((((////****,,,.,,,*/@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#(((/*..,/(/*,*/(((#(((((((////****,,,.,,,**&@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@%%%%%%%%####%%%%%%%%%%%%%%%%%###(((((//**///((#(###(((((///**/,,,,,,**&@@@@@@@@@@@@"
		echo "@@@@@@@@@@@@@@@@&%%%%%%(/(%%%#%%%%%%%%%%%%%#%%%#####(((((((((#(((#(((((/////(**,**(@@@@@@@@@@@@@@@@"
		echo "@@@@@@%(((((((((%%%%%#(%%%%%%%#/##%%%%%%##%%%######(#((((((((((((((((/////%@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "&%&&%,.*/(((((((#%%%%%%%%%%%%%%%#((#(/((##%##((#((#((((((((((((((///////(@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@*(#########%%%%%%%%%%%%%%%%%%%###(((//****//((((((/(((((((////////#@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@%(%%%%%###%%%%%%%%%%%%%%%%%%%%%%%%###(((//(((((///(((###((//////(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@(%%%%%%%%%%%%%%%%%%%%&%&%%%%%%%%%%%%%##((((((((((//(##((/////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@&/%%%%%%%%%%%%%%%%%%%%&%&&%%%%%%%%%%%##(((((((/////((//////...,%@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "&@@@@@@%(%%%%%%%%%%%%%%%%%%%%%%&&&%%%%%%%####(((((///////////*,,.... */(&@@@@@@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@#/%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####(((((////////**,,,,,,,,..*/****#&@@@@@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@((%%%%%%%%%%%%%%%%%%%%%%%%%%%%%####((/////////****,,,,,,,,.*(//////***(%@@@@@@@@@@@@@@@@@"
		echo "@@@@@@@@@@@%(%%%%%%%%%%%%%%%%%%%%%%%#%%%###((//((((////*****,,,,,,,,*(((/(((/*////*//#&@@@@@@@@@@@@"
		echo -e "\e[0m"
		sleep 1
	done
	clear
}

apps=("NINTENDO-SWITCH" "GPARTED" "YOUTUBE-TV" "MINECRAFT" "NETFLIX" "STEAM" "POUPIPOU" "TOOLS")
declare -A commands

# Commandes d'installation pour chaque application
commands["NINTENDO-SWITCH"]="check_internet && curl -L bit.ly/foclabroc-switch-all | bash"
commands["GPARTED"]="check_internet && curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/gparted/gparted.sh | bash"
commands["YOUTUBE-TV"]="check_internet && curl -Ls https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/youtubetv/youtubetv.sh | bash"
commands["MINECRAFT"]="check_internet && curl -Ls https://github.com/DTJW92/batocera-unofficial-addons/raw/main/minecraft/minecraft.sh | bash"
commands["NETFLIX"]="check_internet && curl -Ls https://github.com/DTJW92/batocera-unofficial-addons/raw/main/netflix/netflix.sh | bash"
commands["STEAM"]="check_internet && curl -Ls https://github.com/DTJW92/batocera-unofficial-addons/raw/main/steam/steam.sh | bash"
commands["POUPIPOU"]="display_ascii_art"
commands["TOOLS"]="select_tools"

# Fonction pour afficher le sous-menu des outils
select_tools() {
    local selected=0
    local key
    while true; do
        clear
        display_title
        echo -e "\e[1;37m"
        echo "$CHOOSE"
        echo "-----------------------------------------------------"

        # Affichage des options "SCREENSHOT", "RECORD" et "RETOUR"
        if [[ $selected -eq 0 ]]; then
            echo -e "\e[1;32m>> \e[1;37m[ \e[1;32mSCREENSHOT \e[1;37m] \e[1;34m$DSCREENSHOT \e[1;32m<<\e[1;37m"
            echo -e "   [ RELOAD ] $DRELOAD"
            echo -e "-----------------------------------------------------"
            echo -e "   [ $BACK ]"
        elif [[ $selected -eq 1 ]]; then
            echo -e "   [ SCREENSHOT ] $DSCREENSHOT"
            echo -e "\e[1;32m>> \e[1;37m[ \e[1;32mRELOAD \e[1;37m] \e[1;34m$DRELOAD \e[1;32m<<\e[1;37m"
            echo -e "-----------------------------------------------------"
            echo -e "   [ $BACK ]"
        elif [[ $selected -eq 2 ]]; then
            echo -e "   [ SCREENSHOT ] $DSCREENSHOT"
            echo -e "   [ RELOAD ] $DRELOAD"
            echo -e "-----------------------------------------------------"
            echo -e "\e[1;32m>> \e[1;37m[ \e[1;31m$BACK \e[1;37m] \e[1;32m<<\e[1;37m"
        fi

        # Lecture des touches directionnelles
        read -rsn1 key
        case "$key" in
            $'\x1B')  # Si touche 'flèche'
                read -rsn2 -t 0.1 key
                case "$key" in
                    "[A")  # Flèche Haut
                        ((selected--))
                        if [[ $selected -lt 0 ]]; then
                            selected=2
                        fi
                        ;;
                    "[B")  # Flèche Bas
                        ((selected++))
                        if [[ $selected -gt 2 ]]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            "")  # Si touche Entrée
                if [[ $selected -eq 0 ]]; then
                    echo "$SCREENSHOTMSG1"
                    batocera-screenshot
                    echo -e "\e[1;32m$SCREENSHOTMSG2 \e[1;37m"
                    sleep 2
                elif [[ $selected -eq 1 ]]; then
                    echo "$RELOADESMSG1"
                    curl http://127.0.0.1:1234/reloadgames
                    echo -e "\e[1;32m$RELOADESMSG2 \e[1;37m"
                    sleep 2
                else
                    break
                fi
                sleep 2
                continue 
                ;;
            [Qq])  # Si touche 'Q' pour quitter
                break
                ;;
        esac
    done
}

# Fonction de sélection d'application
select_app() {
    local selected=0
    local key

    while true; do
        clear
        display_title
        echo -e "\e[1;37m"
        echo "$DESCRIPTION"
        echo "---------------------------------------------------------------------"

        # Affichage des applications avec descriptions
        for i in "${!apps[@]}"; do
            if [[ $i -eq $selected ]]; then
                echo -e "\e[1;32m>> \e[1;37m[ \e[1;32m${apps[$i]} \e[1;37m] \e[1;34m- ${descriptions[${apps[$i]}]} \e[1;32m<<\e[0m"
            else
                echo -e "\e[1;37m   [ ${apps[$i]} ] - ${descriptions[${apps[$i]}]}"
            fi
        done

        # Ligne de séparation avant "Quitter"
        echo -e "\e[1;37m---------------------------------------------------------------------"
        if [[ $selected -eq ${#apps[@]} ]]; then
            echo -e "\e[1;31m> [ $QUIT_OPTION ] <\e[0m"
        else
            echo -e "\e[1;37m   [ $QUIT_OPTION ] \e[0m"
        fi

        echo -e "\e[0m"

        read -rsn1 key
        case "$key" in
            $'\x1B')
                read -rsn2 -t 0.1 key
                case "$key" in
                    "[A") ((selected--)); [[ $selected -lt 0 ]] && selected=${#apps[@]} ;;
                    "[B") ((selected++)); [[ $selected -gt ${#apps[@]} ]] && selected=0 ;;
                esac
                ;;
            "") # Entrée
                clear
                if [[ $selected -eq ${#apps[@]} ]]; then
                    echo -e "\e[1;37m$EXIT_MESSAGE"
                    exit 0
                else
                    if [[ ${apps[$selected]} == "POUPIPOU" ]]; then
                        clear
                        display_ascii_art
                    elif [[ ${apps[$selected]} == "TOOLS" ]]; then
                        select_tools  # Lancement du sous-menu des outils
                    else
                        echo -e "\e[1;37m$INTERNET_CHECK"
                        sleep 1
                        check_internet
                        # Choisir Oui ou Non pour installer
                        install_choice=0
                        while true; do
                            clear
                            echo -e "\e[1;37m---------------------------------------------------------------------"
                            echo -e "\e[1;37m$INSTALL_MESSAGE \e[1;32m${apps[$selected]} ? \e[1;37m"
                            echo -e "---------------------------------------------------------------------"
                            echo -e "\n"
                            echo -e "\e[1;37m$CHOOSE"
                            echo "---------------------------------------------------------------------"
                            if [[ $install_choice -eq 0 ]]; then
                                echo -e "\e[1;32m> [ $YES ] <\e[1;37m"
                                echo -e " [ $NO ]"
                            else
                                echo -e " [ $YES ]"
                                echo -e "\e[1;31m> [ $NO ] <\e[1;37m"
                            fi
                            read -rsn1 key
                            case "$key" in
                                $'\x1B')
                                    read -rsn2 -t 0.1 key
                                    case "$key" in
                                        "[A") ((install_choice--)); [[ $install_choice -lt 0 ]] && install_choice=1 ;;
                                        "[B") ((install_choice++)); [[ $install_choice -gt 1 ]] && install_choice=0 ;;
                                    esac
                                    ;;
                                "") # Entrée
                                    if [[ $install_choice -eq 0 ]]; then
                                        echo "$INSTALL_OF ${apps[$selected]}..."
                                        if ! eval "${commands[${apps[$selected]}]}"; then
                                            log_error "$FAILURE_MESSAGE ${apps[$selected]}"
                                            echo -e "\e[1;31m$FAILURE_MESSAGE\e[0m"
                                            sleep 2
                                        else
                                            echo -e "\e[1;32m$SUCCESS_MESSAGE\e[0m"
                                            sleep 2
                                        fi
                                    else
                                        echo -e "\e[1;31m$FAILURE_MESSAGE\e[0m"
                                    fi
                                    break
                                    ;;
                            esac
                        done
                    fi
                fi
                ;;
            [Qq]) 
                echo -e "\e[1;37m$EXIT_MESSAGE"
		killall -9 xterm
                exit 0
                ;;
        esac
    done
}

# Lancement du script
choose_language
set_messages  # Appliquer les traductions en fonction de la langue
select_app
