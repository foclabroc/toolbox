#!/bin/bash

##############################################################
# 🧠 Fonction de traduction
##############################################################

TXT() {
case "$LANGUE:$1" in

1:yes) echo "Yes";;
2:yes) echo "Oui";;

1:no) echo "No";;
2:no) echo "Non";;

1:ok) echo "OK";;
2:ok) echo "OK";;

1:cancel) echo "Cancel";;
2:cancel) echo "Annuler";;

1:step_backup) echo "User data backup";;
2:step_backup) echo "Sauvegarde des données utilisateurs";;

1:step_remove) echo "Removing previous Switch installations";;
2:step_remove) echo "Suppression des anciennes installations Switch";;

1:full_install) echo "Full Switch installation";;
2:full_install) echo "Installation complète Switch";;

1:update_emu) echo "Updates Emulators and System files only";;
2:update_emu) echo "Mise à jours des emulateurs et fichiers systeme seulement";;

1:step_install) echo "Downloading/Installing new Switch pack";;
2:step_install) echo "Téléchargement/Installation du nouveau pack Switch";;

1:step_restore) echo "Restoring user switch save/profils/mods";;
2:step_restore) echo "Restauration des sauvegardes/profils/mods switch";;

1:restore_done) echo "Restoration completed ✔️";;
2:restore_done) echo "Restauration terminée ✔️";;

1:step_cleanup) echo "Cleaning temporary files | Make: [/userdata/Backup_Switch_save_mods.zip]";;
2:step_cleanup) echo "Suppression fichiers temporaires | Création: [/userdata/Backup_Switch_save_mods.zip]";;

1:step_download_pack) echo "Downloading emulator pack";;
2:step_download_pack) echo "Téléchargement du pack émulateurs";;

1:step_extract_pack) echo "Extracting emulator pack";;
2:step_extract_pack) echo "Extraction du pack émulateurs";;


1:welcome) echo "Welcome to the installer";;
2:welcome) echo "Bienvenue dans l’installateur";;

1:downloading) echo "Downloading files...";;
2:downloading) echo "Téléchargement des fichiers...";;

1:finished) echo "Installation completed successfully.";;
2:finished) echo "Installation terminée avec succès.";;

1:error) echo "An error occurred.";;
2:error) echo "Une erreur s’est produite.";;

1:returnmenu) echo "Returning to main menu...";;
2:returnmenu) echo "Retour au menu principal...";;

1:warning_title) echo "WARNING";;
2:warning_title) echo "AVERTISSEMENT";;

1:postinstall_title) echo "Additional installation";;
2:postinstall_title) echo "Installation complémentaire";;

1:postinstall_text) echo "Do you want to install emulator AppImages and firmware + keys 21.1.0 ?";;
2:postinstall_text) echo "Voulez-vous installer les AppImages des émulateurs et le firmware + keys 21.1.0 ?";;

1:extracting) echo "Extracting files...";;
2:extracting) echo "Extraction en cours...";;

1:pack_installed) echo "Pack installed ✔️";;
2:pack_installed) echo "Pack installé ✔️";;

1:finished_title) echo "install completed ✔️";;
2:finished_title) echo "installation terminée ✔️";;

1:speed) echo "Speed";;
2:speed) echo "Vitesse";;

1:Downloaded) echo "Downloaded";;
2:Downloaded) echo "Téléchargé";;

1:Estimated) echo "Estimated time remaining";;
2:Estimated) echo "Temps restant estimé";;

1:archive_created) echo "Archive successfully created";;
2:archive_created) echo "Archive cree avec succes";;

1:size) echo "Size";;
2:size) echo "Taille";;

1:ziperror) echo "ZIP was not created";;
2:ziperror) echo "Le ZIP n'a pas ete cree";;

1:location) echo "Location";;
2:location) echo "Emplacement";;

1:backupT) echo "Backup usersave";;
2:backupT) echo "Sauvegarde usersave";;

1:backupask) echo "Create a ZIP archive of your Switch saves and mods";;
2:backupask) echo "Creer une archive ZIP de vos sauvegardes et mods Switch";;

1:backupask2) echo "ZIP archive of your Switch saves and mods";;
2:backupask2) echo "ZIP de vos sauvegardes et mods Switch";;

1:zip) echo "\nCompression in progress";;
2:zip) echo "\nCompression en cours";;

1:file) echo "Files";;
2:file) echo "Fichiers";;

1:zipF) echo "Compression Done";;
2:zipF) echo "Compression Termine";;

1:download_finished) echo "Download complete";;
2:download_finished) echo "Telechargement termine";;

1:finalizing) echo "\nFinalizing...\n\n[may take some time if you have large Mods like (CTGP-DX...)]";;
2:finalizing) echo "\nFinalisation...\n\n[peut prendre du temps si vous avez de gros Mods comme (CTGP-DX...)]";;

1:update_emu_title) echo "Emulator update";;
2:update_emu_title) echo "Mise à jour des émulateurs";;

1:update_emu_ask) echo "Do you want to update emulator AppImages now?";;
2:update_emu_ask) echo "Voulez-vous mettre à jour les AppImages des émulateurs maintenant ?";;

1:update_emu_running) echo "Updating emulator AppImages...";;
2:update_emu_running) echo "Mise à jour des AppImages des émulateurs...";;

1:finished_full) cat <<EOF
Switch installation completed

✔️ Your saves / profiles / mods have been restored
A backup has been created (If you selected "yes" to the request to create the zip file) in :
/userdata/backup_save_mods_switch

✔️ If you have downloaded the appimages+firmware package mentioned earlier,
firmware 21.1.0 and its keys have been installed and also necessary appimages.
(you may update it if needed)

✔️ If you haven't downloaded the appimages+firmware package mentioned earlier,
please place your appimages in /userdata/system/switch/appimages
and switch firmware/keys in /userdata/bios/switch.

✔️ F1 application configuration has been removed
(for better controller detection)
You can find new configuration apps in :
Roms/switch → Ryujinx config App
Roms/switch → Eden config App
Roms/switch → Citron config App
Ports → Switch Appimages Updater
Mouse navigation : Right stick
Click : L1 / R1
Exit : Hotkey + Start
✔️ But also the real Switch menu (Qlauncher) in /roms/switch: "1-Switch Home Menu (Only with Eden-emu)"

✔️ Controller auto-configuration works on all emulators
(Tested with DS4 / Switch Pro Controller / SteamDeck)

Thanks Spirit for autoconfig and DreamerCG for fix Xbox autoconfig
EOF
;;

2:finished_full) cat <<EOF
Installation Switch terminée

✔️ Vos saves / profils / mods ont été restaurés
Un backup a été créé (si vous avez selectionné oui a la demande creation du zip) dans :
/userdata/backup_save_mods_switch

✔️ Si vous avez téléchargé le pack AppImages + firmware mentionné précédemment,
le firmware 21.1.0 ainsi que ses clés ont été installés, ainsi que les AppImages nécessaires.
(vous pourrez les mettre à jour si besoin)

✔️ Si vous n’avez pas téléchargé le pack AppImages + firmware mentionné précédemment,
merci de placer vos AppImages dans : /userdata/system/switch/appimages
et le firmware/keys Switch dans : /userdata/bios/switch

✔️ La configuration F1 des applications a été supprimée
(par souci de détection manette)

Vous trouverez les nouvelles applis de configuration dans :
Roms/switch → Ryujinx config App
Roms/switch → Eden config App
Roms/switch → Citron config App
Ports → Switch Appimages Updater
Navigation souris : Stick droit
Clic : L1 / R1
Quitter : Hotkey + Start
✔️ Mais egalement le vrai menu Switch (Qlauncher) dans /roms/switch : "1-Switch Home Menu (Only with Eden-emu)"

✔️ L'autoconfiguration des manettes fonctionne pour tous les émulateurs
(Testé sur DS4 / Switch Pro Controller / SteamDeck)

Merci Spirit pour l'autoconfig et DreamerCG pour le fix Xbox autoconfig
EOF
;;


1:warning_text) cat <<EOF
NEW SWITCH INSTALLER (Batocera V42+ x86_64 only !) !!!!!IMPORTANT USERDATA MUST BE IN EXT4 OR BTRFS!!!!!
This new Switch installation script will completely remove all folders/files from previous installations.

A backup of your Switch saves, mods and profiles will be automatically created and restored at the end of the installation.

However, it is strongly recommended that you manually back up your saves/mods/profiles before running the script.

Folders to back up for safety:

/system/configs/yuzu/nand
/system/configs/yuzu/load
/system/configs/Ryujinx/bis
/system/configs/Ryujinx/mods

After installation you will be able to choose between:
- Eden
- Eden-pgo
- Citron
- Ryujinx (ryubing)

Yuzu and Sudachi have been removed because they are no longer maintained.



Do you want to continue ?
EOF
;;

2:warning_text) cat <<EOF
NOUVEL INSTALLEUR SWITCH (Batocera V42+ x86_64 uniquement !) !!!!!IMPORTANT : VOTRE SHARE DOIT OBLIGATOIREMENT ETRE EN EXT4 OU BTRFS!!!!!
Ce nouveau script Switch va supprimer complètement tous les dossiers/fichiers des installations précédentes.

Une sauvegarde de vos saves, mods et profils Switch sera automatiquement réalisée et restaurée en fin d’installation.

Mais je vous conseille fortement de faire une sauvegarde manuelle avant de lancer le script.

Dossiers à sauvegarder par prudence :

/system/configs/yuzu/nand
/system/configs/yuzu/load
/system/configs/Ryujinx/bis
/system/configs/Ryujinx/mods

Après l’installation vous aurez le choix entre :
- Eden
- Eden-pgo
- Citron
- Ryujinx (ryubing)

Yuzu et Sudachi ont été supprimés car ils ne sont plus mis à jour.



Voulez-vous continuer ?
EOF
;;

*) echo "$1";;
esac
}

BACKTITLE="Foclabroc Toolbox"

# Choix de la langue au lancement
LANGUE=$(dialog --backtitle "$BACKTITLE" \
                --title "$(TXT welcome)" \
                --ok-label "Select" \
                --cancel-label "Cancel" \
                --menu "\nChoose your language / Choisissez votre langue :" 11 55 2 \
                1 "English" \
                2 "Français" \
                3>&1 1>&2 2>&3)

clear
[ -z "$LANGUE" ] && exit 0

##############################################################
# 📦 Choix du mode
##############################################################

MODE=$(dialog --backtitle "$BACKTITLE" \
              --title "$(TXT welcome)" \
              --ok-label "$(TXT ok)" \
              --cancel-label "$(TXT cancel)" \
              --menu "\nChoisissez une action / Choose an action:" 11 80 2 \
              1 "$(TXT update_emu)" \
              2 "$(TXT full_install)" \
              3>&1 1>&2 2>&3)

clear
[ -z "$MODE" ] && exit 0

##############################################################
# ▶️ Lancement selon le mode choisi
##############################################################

if [[ "$MODE" == "1" ]]; then
    dialog --backtitle "$BACKTITLE" \
           --infobox "\nUpdate AppImages..." 5 60
    sleep 1

    clear
    curl -fsSL --retry 3 https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/appimage_updater.sh | bash
    exit 0
fi

##############################################################
# ⚠️ Avertissement au lancement
##############################################################

printf "%b" "\n$(TXT warning_text)" | \
dialog --backtitle "$BACKTITLE" \
       --title "$(TXT warning_title)" \
       --yes-label "$(TXT yes)" \
       --no-label "$(TXT no)" \
       --yesno "$(cat)" 36 100 2>&1 >/dev/tty

if [[ $? -ne 0 ]]; then
    dialog --backtitle "$BACKTITLE" --infobox "\n$(TXT returnmenu)" 5 60 2>&1 >/dev/tty
    sleep 2
    exit 0
fi

mark_step_done() {
    local done="$1"
    for ((i=0; i<${#STEPS[@]}; i+=3)); do
        [[ "${STEPS[i]}" == "$done" ]] && STEPS[i+2]="on"
    done
}

STEPS=(
"backup"   "$(TXT step_backup)"   off
"remove"   "$(TXT step_remove)"   off
"install"  "$(TXT step_install)"  off
"restore"  "$(TXT step_restore)"  off
"cleanup"  "$(TXT step_cleanup)"  off
)

update_steps() {
    local current="$1"

    TMPFILE="/tmp/dialog_steps.txt"
    : > "$TMPFILE"

    echo "" >> "$TMPFILE"

    for ((i=0; i<${#STEPS[@]}; i+=3)); do
        id="${STEPS[i]}"
        text="${STEPS[i+1]}"
        state="${STEPS[i+2]}"

        prefix="[ ]"
        [[ "$state" == "on" ]] && prefix="[OK]"

        if [[ "$id" == "$current" ]]; then
            line=">> $text"
        else
            line="$prefix $text"
        fi

        echo "$line" >> "$TMPFILE"
        echo "" >> "$TMPFILE"
    done

    dialog --backtitle "$BACKTITLE" \
           --title "Installation" \
           --infobox "$(cat "$TMPFILE")" 14 94
}


backup_switch_data() {

    mkdir -p /userdata/tmp/
    mkdir -p /userdata/tmp/tmp_yuzu_mods
    mkdir -p /userdata/tmp/tmp_yuzu_save_user
    mkdir -p /userdata/tmp/tmp_yuzu_save_system
    mkdir -p /userdata/tmp/tmp_ryujinx_save_user
    mkdir -p /userdata/tmp/tmp_ryujinx_save_system
    mkdir -p /userdata/tmp/tmp_ryujinx_mods

	# Activer le déplacement des fichiers cachés
	shopt -s dotglob

	[ -d "/userdata/system/configs/yuzu/load" ] && \
	[ "$(ls -A /userdata/system/configs/yuzu/load 2>/dev/null)" ] && \
	mv /userdata/system/configs/yuzu/load/* /userdata/tmp/tmp_yuzu_mods/ 2>/dev/null

	[ -d "/userdata/system/configs/yuzu/nand/user/save" ] && \
	[ "$(ls -A /userdata/system/configs/yuzu/nand/user/save 2>/dev/null)" ] && \
	mv /userdata/system/configs/yuzu/nand/user/save/* /userdata/tmp/tmp_yuzu_save_user/ 2>/dev/null

	[ -d "/userdata/system/configs/yuzu/nand/system/save" ] && \
	[ "$(ls -A /userdata/system/configs/yuzu/nand/system/save 2>/dev/null)" ] && \
	mv /userdata/system/configs/yuzu/nand/system/save/* /userdata/tmp/tmp_yuzu_save_system/ 2>/dev/null

	[ -d "/userdata/system/configs/Ryujinx/bis/user" ] && \
	[ "$(ls -A /userdata/system/configs/Ryujinx/bis/user 2>/dev/null)" ] && \
	mv /userdata/system/configs/Ryujinx/bis/user/* /userdata/tmp/tmp_ryujinx_save_user/ 2>/dev/null

	[ -d "/userdata/system/configs/Ryujinx/bis/system/save" ] && \
	[ "$(ls -A /userdata/system/configs/Ryujinx/bis/system/save 2>/dev/null)" ] && \
	mv /userdata/system/configs/Ryujinx/bis/system/save/* /userdata/tmp/tmp_ryujinx_save_system/ 2>/dev/null

	[ -d "/userdata/system/configs/Ryujinx/mods" ] && \
	[ "$(ls -A /userdata/system/configs/Ryujinx/mods 2>/dev/null)" ] && \
	mv /userdata/system/configs/Ryujinx/mods/* /userdata/tmp/tmp_ryujinx_mods/ 2>/dev/null

	# Désactiver après usage (important)
	shopt -u dotglob
	
	mark_step_done "backup"
}

remove_old_installations() {

    TARGETS=(
        /userdata/bios/switch
        /userdata/system/switch
        /userdata/system/configs/yuzu
        /userdata/system/configs/citron
        /userdata/system/configs/Ryujinx
        /userdata/system/configs/sudachi
        /userdata/system/configs/suyu
        /userdata/system/configs/eden
        /userdata/system/configs/emulationstation/es_systems_switch.cfg
        /userdata/system/configs/emulationstation/es_features_switch.cfg
        /userdata/system/configs/evmapy/switch.keys
        /userdata/saves/yuzu
        /userdata/saves/citron
        /userdata/saves/Ryujinx
        /userdata/saves/eden
        /userdata/system/.cache/yuzu
        /userdata/system/.cache/citron
        /userdata/system/.cache/eden
        /userdata/system/.cache/sudachi
        /userdata/system/.cache/Ryujinx
        /userdata/system/.cache/radv_builtin_shaders
        /userdata/system/.cache/mesa_shader_cache
        /userdata/system/cache/radv_builtin_shaders
        /userdata/system/cache/mesa_shader_cache
        /userdata/system/.config/Ryujinx
        /userdata/system/.config/yuzu
        /userdata/system/.config/yuzu-early-access
        /userdata/system/.config/citron
        /userdata/system/.config/eden
        /userdata/system/.local/share/eden
        /userdata/system/.local/share/yuzu
        /userdata/system/.local/share/yuzu-early-access
        /userdata/roms/ports/Sudachi\ Qlauncher.sh
        /userdata/roms/ports/Sudachi\ Qlauncher.sh.keys
        /userdata/roms/ports/Switch\ Updater40.sh
        /userdata/roms/ports/Switch\ Updater40.sh.keys
        /userdata/roms/ports/Switch\ Updater.sh
        /userdata/roms/ports/Switch\ Updater.sh.keys
        /userdata/roms/ports/ryujinx_config.sh
        /userdata/roms/ports/ryujinx_config.sh.keys
        /userdata/roms/ports/yuzu_config.sh
        /userdata/roms/ports/yuzu_config.sh.keys
        /userdata/roms/ports/Suyu\ Qlauncher.sh
        /userdata/roms/ports/Suyu\ Qlauncher.sh.keys
        /userdata/roms/ports/citron_config.sh
        /userdata/roms/ports/citron_config.sh.keys
        /userdata/roms/ports/images/citron_config.png
        /userdata/roms/ports/images/citron_config_logo.png
        /userdata/roms/ports/images/citron_config_screen.png
        /userdata/roms/ports/images/ryujinx_config_logo.png
        /userdata/roms/ports/images/ryujinx_config_screen.png
        /userdata/roms/ports/images/ryujinx_config.png
        /userdata/roms/ports/images/yuzu_config_screen.png
        /userdata/roms/ports/images/yuzu_config_logo.png
        /userdata/roms/ports/images/yuzu_config.png
        /userdata/roms/switch/_Switch-Home-menu.xci
    )

    # Suppression des chemins exacts
    for path in "${TARGETS[@]}"; do
        rm -rf "$path" 2>/dev/null
    done

    # Suppression via patterns (glob)
    rm -rf /userdata/roms/ports/update*yuzu*.sh 2>/dev/null

    rm -rf /usr/share/applications/*yuzu* 2>/dev/null
    rm -rf /usr/share/applications/*ryujinx* 2>/dev/null
    rm -rf /usr/share/applications/*eden* 2>/dev/null
    rm -rf /usr/share/applications/*citron* 2>/dev/null
    rm -rf /usr/share/applications/*suyu* 2>/dev/null
    rm -rf /usr/share/applications/*sudachi* 2>/dev/null

    rm -rf /userdata/system/.local/share/applications/*yuzu* 2>/dev/null
    rm -rf /userdata/system/.local/share/applications/*ryujinx* 2>/dev/null
    rm -rf /userdata/system/.local/share/applications/*eden* 2>/dev/null
    rm -rf /userdata/system/.local/share/applications/*citron* 2>/dev/null
    rm -rf /userdata/system/.local/share/applications/*suyu* 2>/dev/null
    rm -rf /userdata/system/.local/share/applications/*sudachi* 2>/dev/null

    # Nettoyage du custom.sh
    CUSTOM="/userdata/system/custom.sh"
    if [[ -f "$CUSTOM" ]]; then
        sed -i '\|/userdata/system/switch/extra/batocera-switch-startup|d' "$CUSTOM"
    fi
    
    BATOCERA_CONF="/userdata/system/batocera.conf"
	if [[ -f "$BATOCERA_CONF" ]]; then
		# Récupère la langue système Batocera
		batocera_language=$(grep '^system.language=' "$BATOCERA_CONF" | cut -d '=' -f2)
		
		# Supprime toutes les anciennes lignes switch
		sed -i '/^switch/d' "$BATOCERA_CONF"
		
		# Ajoute la config UNIQUEMENT si absente
		grep -q 'switch\["citron_config.xci_config"\]\.core=citron-emu' "$BATOCERA_CONF" || \
		echo 'switch["citron_config.xci_config"].core=citron-emu' >> "$BATOCERA_CONF"
		grep -q 'switch\["citron_config.xci_config"\]\.emulator=citron-emu' "$BATOCERA_CONF" || \
		echo 'switch["citron_config.xci_config"].emulator=citron-emu' >> "$BATOCERA_CONF"

		grep -q 'switch\["eden_qlaunch.xci_config"\]\.core=eden-emu' "$BATOCERA_CONF" || \
		echo 'switch["eden_qlaunch.xci_config"].core=eden-emu' >> "$BATOCERA_CONF"
		grep -q 'switch\["eden_qlaunch.xci_config"\]\.emulator=eden-emu' "$BATOCERA_CONF" || \
		echo 'switch["eden_qlaunch.xci_config"].emulator=eden-emu' >> "$BATOCERA_CONF"

		grep -q 'switch\["eden_config.xci_config"\]\.core=eden-emu' "$BATOCERA_CONF" || \
		echo 'switch["eden_config.xci_config"].core=eden-emu' >> "$BATOCERA_CONF"
		grep -q 'switch\["eden_config.xci_config"\]\.emulator=eden-emu' "$BATOCERA_CONF" || \
		echo 'switch["eden_config.xci_config"].emulator=eden-emu' >> "$BATOCERA_CONF"

		grep -q 'switch\["ryujinx_config.xci_config"\]\.core=ryujinx-emu' "$BATOCERA_CONF" || \
		echo 'switch["ryujinx_config.xci_config"].core=ryujinx-emu' >> "$BATOCERA_CONF"
		grep -q 'switch\["ryujinx_config.xci_config"\]\.emulator=ryujinx-emu' "$BATOCERA_CONF" || \
		echo 'switch["ryujinx_config.xci_config"].emulator=ryujinx-emu' >> "$BATOCERA_CONF"

		# Préconfiguration langue FR si Batocera est en français
		if [ "$batocera_language" = "fr_FR" ]; then
			grep -q "^switch.region=" "$BATOCERA_CONF" || echo "switch.region=2" >> "$BATOCERA_CONF"
			grep -q "^switch.language=" "$BATOCERA_CONF" || echo "switch.language=2" >> "$BATOCERA_CONF"
			grep -q "^switch.system_language=" "$BATOCERA_CONF" || echo "switch.system_language=French" >> "$BATOCERA_CONF"
			grep -q "^switch.system_region=" "$BATOCERA_CONF" || echo "switch.system_region=Europe" >> "$BATOCERA_CONF"
			grep -q "^switch.yuzu_intlanguage=" "$BATOCERA_CONF" || echo "switch.yuzu_intlanguage=fr" >> "$BATOCERA_CONF"
		fi
	fi

    mark_step_done "remove"
}

install_new_pack() {

    PACK_URL="https://github.com/foclabroc/New-batocera-switch/archive/refs/heads/main.zip"
    PACK_ZIP="/userdata/tmp/pack.zip"
    EXTRACT_DIR="/userdata/tmp/new_switch_pack"

    mkdir -p /userdata/tmp
    rm -rf "$PACK_ZIP"

    # Télécharger
	wget -q --tries=3 --timeout=20 --retry-connrefused -O "$PACK_ZIP" "$PACK_URL"
	WGET_STATUS=$?

	if [ $WGET_STATUS -ne 0 ] || [ ! -s "$PACK_ZIP" ]; then
		dialog --title "Erreur téléchargement" \
			   --msgbox "Impossible de télécharger le pack après plusieurs tentatives." 8 60
		rm -f "$PACK_ZIP"
		return 1
	fi

    # Extraire
    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"

    unzip -o "$PACK_ZIP" -d "$EXTRACT_DIR" >/dev/null

    # Trouver automatiquement le dossier racine extrait
    ROOT_DIR=$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)

	# Vérification de sécurité
	[[ -d "$ROOT_DIR" ]] || {
		dialog --backtitle "$BACKTITLE" --msgbox "\n$(TXT error)\nExtraction failed." 6 50
		exit 1
	}

    # Copier uniquement son contenu dans /userdata
	shopt -s dotglob nullglob
	cp -r "$ROOT_DIR"/* /userdata/
	shopt -u dotglob nullglob

    gamelist_file="/userdata/roms/ports/gamelist.xml"
    gamelist_file2="/userdata/roms/switch/gamelist.xml"

    # Ensure the gamelist.xml exists
    if [ ! -f "$gamelist_file" ]; then
        echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$gamelist_file"
    fi

	if [ ! -f "$gamelist_file2" ]; then
		echo '<?xml version="1.0" encoding="UTF-8"?><gameList></gameList>' > "$gamelist_file2"
	fi

    # Installation de xmlstarlet si absent.
    XMLSTARLET_DIR="/userdata/system/switch/extra"
    XMLSTARLET_BIN="$XMLSTARLET_DIR/xmlstarlet"
    XMLSTARLET_SYMLINK="/usr/bin/xmlstarlet"

    if [ -f "$XMLSTARLET_BIN" ]; then
        chmod +x "$XMLSTARLET_BIN"
        ln -sf "$XMLSTARLET_BIN" "$XMLSTARLET_SYMLINK"
    fi

remove_game_by_path() {
    local file="$1"
    local gamepath="$2"

    xmlstarlet ed -L -d "/gameList/game[path='$gamepath']" "$file" 2>/dev/null
}

    # Supprimer anciennes entrées
    remove_game_by_path "$gamelist_file" "./updateryujinx.sh"
    remove_game_by_path "$gamelist_file" "./updateryujinxavalonia.sh"
    remove_game_by_path "$gamelist_file" "./batocera-switch-installer.sh"
    remove_game_by_path "$gamelist_file" "./Suyu Qlauncher.sh"
    remove_game_by_path "$gamelist_file" "./batocera-switch-updater.sh"
    remove_game_by_path "$gamelist_file" "./Switch Updater.sh"
    remove_game_by_path "$gamelist_file" "./updateyuzuEA.sh"
    remove_game_by_path "$gamelist_file" "./updateyuzu.sh"
    remove_game_by_path "$gamelist_file" "./ryujinx_config.sh"
    remove_game_by_path "$gamelist_file" "./yuzu_config.sh"
    remove_game_by_path "$gamelist_file" "./citron_config.sh"
    remove_game_by_path "$gamelist_file2" "./_Switch-Home-menu.xci"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file2" "./ryujinx_config.sh"
    # Ajouter Ryujinx Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./ryujinx_config.xci_config" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "1-Ryujinx Config App" \
        -s "/gameList/game[last()]" -t elem -n "desc" -v "Lancement de RYUJINX en mode application pour configuration manuelle." \
        -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "genre" -v "Switch" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
        -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/ryujinx_config_screen.png" \
        -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/ryujinx_config_logo.png" \
        -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/ryujinx_config.png" \
        "$gamelist_file2"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file2" "./yuzu_config.sh"
    # Ajouter Eden Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./eden_config.xci_config" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "1-Eden Config App" \
        -s "/gameList/game[last()]" -t elem -n "desc" -v "Lancement de EDEN en mode application pour configuration manuelle de Eden." \
        -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "genre" -v "Switch" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
        -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/yuzu_config_screen.png" \
        -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/yuzu_config_logo.png" \
        -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/yuzu_config.png" \
        "$gamelist_file2"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file2" "./citron_config.sh"
    # Ajouter Citron Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./citron_config.xci_config" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "1-Citron Config App" \
        -s "/gameList/game[last()]" -t elem -n "desc" -v "Lancement de CITRON en mode application pour configuration manuelle de Citron." \
        -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc DreamerCG Spirit" \
        -s "/gameList/game[last()]" -t elem -n "genre" -v "Switch" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
        -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/citron_config_screen.png" \
        -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/citron_config_logo.png" \
        -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/citron_config.png" \
        "$gamelist_file2"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file" "./Switch AppImages Updater.sh"
    # Ajouter Updater
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./Switch AppImages Updater.sh" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "Switch Emulator Updater" \
        -s "/gameList/game[last()]" -t elem -n "desc" -v "Script de Mise à jour des emulateurs Switch." \
        -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc" \
        -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc" \
        -s "/gameList/game[last()]" -t elem -n "genre" -v "Switch" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
        -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/updater_app_screen.png" \
        -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/updater_app_logo.png" \
        -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/updater_app.png" \
        "$gamelist_file"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file2" "./eden_qlaunch.xci_config"
    # Ajouter Qlauncher
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./eden_qlaunch.xci_config" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "1-Switch Home Menu (Only with Eden-emu)" \
        -s "/gameList/game[last()]" -t elem -n "desc" -v "Démarrage en mode Ecran d'accueil Switch réel (qlauncher) A lancer uniquement avec EDEN !!!." \
        -s "/gameList/game[last()]" -t elem -n "developer" -v "Foclabroc" \
        -s "/gameList/game[last()]" -t elem -n "publisher" -v "Foclabroc" \
        -s "/gameList/game[last()]" -t elem -n "genre" -v "Switch" \
        -s "/gameList/game[last()]" -t elem -n "rating" -v "1.00" \
        -s "/gameList/game[last()]" -t elem -n "region" -v "eu" \
        -s "/gameList/game[last()]" -t elem -n "lang" -v "fr" \
        -s "/gameList/game[last()]" -t elem -n "image" -v "./images/_Switch-Home-menu-screen.png" \
        -s "/gameList/game[last()]" -t elem -n "wheel" -v "./images/_Switch-Home-menu-logo.png" \
        -s "/gameList/game[last()]" -t elem -n "thumbnail" -v "./images/_Switch-Home-menu-box.png" \
        "$gamelist_file2"

        for file in "$gamelist_file" "$gamelist_file2"; do
            [ -f "$file" ] && sed -i '/<sortname>[^<]*<\/sortname>/d' "$file"
        done

    rm -rf "/userdata/README.md"
    mark_step_done "install"
}

restore_switch_data() {

    move_content() {
        SRC="$1"
        DEST="$2"

        if [[ -d "$SRC" ]]; then
            mkdir -p "$DEST"

            shopt -s dotglob nullglob
            mv "$SRC"/* "$DEST"/ 2>/dev/null
            shopt -u dotglob nullglob
        fi
    }

    move_content "/userdata/tmp/tmp_yuzu_mods" "/userdata/saves/switch/eden_citron/mods"
    move_content "/userdata/tmp/tmp_yuzu_save_user" "/userdata/saves/switch/eden_citron/save/save_user"
    move_content "/userdata/tmp/tmp_yuzu_save_system" "/userdata/saves/switch/eden_citron/save/save_system"

    move_content "/userdata/tmp/tmp_ryujinx_save_user" "/userdata/saves/switch/ryujinx/save/save_user"
    move_content "/userdata/tmp/tmp_ryujinx_save_system" "/userdata/saves/switch/ryujinx/save/save_system"
    move_content "/userdata/tmp/tmp_ryujinx_mods" "/userdata/saves/switch/ryujinx/mods"

    mark_step_done "restore"
}

ask_zip_backup() {

    DO_ZIP="no"

    dialog --backtitle "$BACKTITLE" \
           --title "$(TXT backupT)" \
           --yes-label "$(TXT yes)" \
           --no-label "$(TXT no)" \
           --yesno "\n$(TXT backupask) ?" 8 63 2>&1 >/dev/tty

    if [[ $? -eq 0 ]]; then
        DO_ZIP="yes"
    fi

    cleanup_temp_files
}

zip_with_gauge() {

    SRC_DIR="$1"
    ZIP_FILE="$2"

    BASE_DIR="/userdata"
    cd "$BASE_DIR" || exit 1

    TOTAL=$(find "saves/switch" -type f | wc -l)
    [ "$TOTAL" -eq 0 ] && TOTAL=1

    COUNT=0
    FINALIZING="no"

    (
        zip -r -0 -v "$ZIP_FILE" "saves/switch" 2>/dev/null | while read -r line; do
            if [[ "$line" == adding:* ]]; then
                ((COUNT++))
                PERCENT=$(( COUNT * 100 / TOTAL ))
                if [[ "$PERCENT" -ge 99 ]]; then
                    PERCENT=99
                    FINALIZING="yes"
                fi
                echo "$PERCENT"
                echo "XXX"
                echo "────────────────────────────────────────"
                if [[ "$FINALIZING" == "yes" ]]; then
                    echo "$(TXT finalizing)"
                else
                    echo "$(TXT zip)"
                fi
                echo ""
                echo ""
                echo "$PERCENT %"
                echo "XXX"
            fi
        done
        sync

        echo "100"
        echo "XXX"
        echo "$(TXT zipF)"
        echo "XXX"

    ) | dialog --backtitle "$BACKTITLE" \
               --title "$(TXT backupask2)" \
               --gauge "$(TXT zip)" 14 60 0


    if [[ -f "$ZIP_FILE" ]]; then
        SIZE_MB=$(( $(stat -c%s "$ZIP_FILE") / 1024 / 1024 ))

        dialog --backtitle "$BACKTITLE" \
               --title "$(TXT zipF)" \
               --ok-label "$(TXT ok)" \
               --msgbox "\n$(TXT archive_created)\n\n$(TXT size) : ${SIZE_MB} MB\n\n$(TXT location) : $ZIP_FILE" 12 80
    else
        dialog --backtitle "$BACKTITLE" \
               --msgbox "\n$(TXT ziperror)" 6 40
    fi
}


cleanup_temp_files() {

    TMP_BASE="/userdata/tmp"
    SWITCH_SAVES="/userdata/saves/switch"
    DATE_TAG=$(date +"%Y-%m-%d_%H-%M-%S")
    ZIP_FILE="/userdata/Backup_Switch_save_mods_${DATE_TAG}.zip"

    if [[ "$DO_ZIP" == "yes" && -d "$SWITCH_SAVES" ]]; then
        zip_with_gauge "$SWITCH_SAVES" "$ZIP_FILE"
    fi

    rm -rf "$TMP_BASE" 2>/dev/null
    sync

    mark_step_done "cleanup"
}

post_install_prompt() {
    sleep 2
    dialog --backtitle "$BACKTITLE" \
           --title "$(TXT postinstall_title)" \
           --yes-label "$(TXT yes)" \
           --no-label "$(TXT no)" \
           --yesno "\n$(TXT postinstall_text)" 8 60 2>&1 >/dev/tty

    if [[ $? -eq 0 ]]; then
        dialog --backtitle "$BACKTITLE" --infobox "\n$(TXT downloading)" 5 50 2>&1 >/dev/tty
        sleep 1

        install_emulators_pack
    fi
}

install_emulators_pack() {

    ZIP_URL="https://foclabroc.freeboxos.fr:55973/share/j4HRYFkF_tq5IV_A/firmware_appimage_21.1.zip"
    ZIP_FILE="/userdata/tmp/firmware_appimage.zip"

    mkdir -p /userdata/tmp
    rm -rf "$ZIP_FILE"

    download_with_gauge "$ZIP_URL" "$ZIP_FILE"

    if [[ ! -s "$ZIP_FILE" ]]; then
        dialog --msgbox "\n$(TXT error)" 7 40
        return 1
    fi

    extract_with_gauge "$ZIP_FILE" "/userdata/"

	NCA_SRC_DIR="/userdata/bios/switch/firmware"
	KEYS_SRC_DIR="/userdata/bios/switch/keys"
	RYUJINX_SYSTEM_DIR="/userdata/system/configs/Ryujinx/system"
	REGISTERED_DIR="/userdata/system/configs/Ryujinx/bis/system/Contents/registered"
	CHECKSUM_FILE="/userdata/system/configs/Ryujinx/checksum_firmware.txt"

	mkdir -p "$RYUJINX_SYSTEM_DIR"
	mkdir -p "$REGISTERED_DIR"

	# Copier les keys
	if [ -d "$KEYS_SRC_DIR" ]; then
		cp -p "$KEYS_SRC_DIR"/* "$RYUJINX_SYSTEM_DIR/" 2>/dev/null
	fi

	# Copier le firmware uniquement si modifié
	if [ -d "$NCA_SRC_DIR" ]; then
		cd "$NCA_SRC_DIR" || exit 1
		TMP_CHECKSUM=$(find . -type f -exec sha256sum {} + | sort | sha256sum | awk '{print $1}')

		[ -f "$CHECKSUM_FILE" ] && STORED_CHECKSUM=$(cat "$CHECKSUM_FILE") || STORED_CHECKSUM=""

		if [ "$TMP_CHECKSUM" != "$STORED_CHECKSUM" ]; then
			rm -rf "$REGISTERED_DIR"/*

			shopt -s nullglob
			for f in "$NCA_SRC_DIR"/*.nca; do
				filename=$(basename "$f")
				mkdir -p "$REGISTERED_DIR/$filename"
				cp -p "$f" "$REGISTERED_DIR/$filename/00"
			done
			shopt -u nullglob

			echo "$TMP_CHECKSUM" > "$CHECKSUM_FILE"
		fi
	fi


    rm -rf "/userdata/tmp"

    dialog --backtitle "$BACKTITLE" --ok-label "$(TXT ok)" --msgbox "\n$(TXT pack_installed)" 7 40
}


download_with_gauge() {

    URL="$1"
    DEST_FILE="$2"

    mkdir -p "$(dirname "$DEST_FILE")"
    rm -f "$DEST_FILE"

    # Taille totale du fichier (si dispo)
    poids_bytes=$(wget --spider "$URL" 2>&1 | awk '/Length:/ {print $2}')
    [ -z "$poids_bytes" ] && poids_bytes=600000000

    poids=$((poids_bytes / 1024 / 1024))
    START_TIME=$(date +%s)

    # Lancer le téléchargement en arrière-plan
    wget -q --tries=3 --timeout=20 --retry-connrefused -O "$DEST_FILE" "$URL" &
    PID_WGET=$!

    (
    LAST_SIZE=0

    while kill -0 $PID_WGET 2>/dev/null; do
        if [ -f "$DEST_FILE" ]; then
            CURRENT_SIZE=$(stat -c%s "$DEST_FILE" 2>/dev/null)
            LAST_SIZE=$CURRENT_SIZE

            NOW=$(date +%s)
            ELAPSED=$((NOW - START_TIME))
            [ "$ELAPSED" -eq 0 ] && ELAPSED=1

            SPEED_BPS=$((CURRENT_SIZE / ELAPSED))
            SPEED_MO=$(echo "scale=2; $CURRENT_SIZE / $ELAPSED / 1048576" | bc)

            CURRENT_MB=$((CURRENT_SIZE / 1024 / 1024))
            TOTAL_MB=$poids

            REMAINING_BYTES=$((poids_bytes - CURRENT_SIZE))
            [ "$SPEED_BPS" -le 0 ] && SPEED_BPS=1

            ETA_SEC=$((REMAINING_BYTES / SPEED_BPS))
            ETA_MIN=$((ETA_SEC / 60))
            ETA_REST_SEC=$((ETA_SEC % 60))
            ETA_FORMAT=$(printf "%02d:%02d" "$ETA_MIN" "$ETA_REST_SEC")

            PROGRESS=$((CURRENT_SIZE * 100 / poids_bytes))
            [ "$PROGRESS" -gt 100 ] && PROGRESS=100
            [ "$PROGRESS" -lt 0 ] && PROGRESS=0

            echo "$PROGRESS"
            echo "XXX"
            echo "────────────────────────────────────────"
            echo "$(TXT downloading)"
            echo ""
            echo "$(TXT speed) : ${SPEED_MO} Mo/s"
            echo "$(TXT Downloaded) : ${CURRENT_MB} / ${TOTAL_MB} Mo"
            echo "$(TXT Estimated) : ${ETA_FORMAT}"
            echo "XXX"
        fi
        sleep 0.5
    done

    FINAL_SIZE=$(stat -c%s "$DEST_FILE" 2>/dev/null)

    # Si le fichier est très incomplet (<90%) → erreur affichée dans la jauge
    if [ -z "$FINAL_SIZE" ] || [ "$FINAL_SIZE" -lt $((poids_bytes * 90 / 100)) ]; then
        echo "0"
        echo "XXX"
        echo "$(TXT download_error)"
        echo "$(TXT check_connection)"
        echo "XXX"
        sleep 2
    else
        echo "100"
        echo "XXX"
        echo "$(TXT download_finished)"
        echo "XXX"
    fi

    ) | dialog --backtitle "$BACKTITLE" \
               --title "$(TXT step_download_pack)" \
               --gauge "$(TXT downloading)" 12 70 0

    # Attendre proprement la fin de wget (dans le bon shell)
    wait $PID_WGET 2>/dev/null

    FILE_SIZE=$(stat -c%s "$DEST_FILE" 2>/dev/null)

    # Vérification finale de sécurité
    if [ -z "$FILE_SIZE" ] || [ "$FILE_SIZE" -lt 1048576 ]; then
        dialog --title "$(TXT download_error)" \
               --msgbox "$(TXT check_connection)" 8 50
        rm -f "$DEST_FILE"
        return 1
    fi
}



extract_with_gauge() {
    [[ "$TOTAL" -gt 0 ]] || TOTAL=1
    ZIP="$1"
    DEST="$2"

    TOTAL=$(unzip -l "$ZIP" | awk 'NR>3 {count++} END{print count}')
    COUNT=0

    unzip -o "$ZIP" -d "$DEST" 2>/dev/null | \
    grep -E '^  inflating:|^ extracting:' | \
    while read -r file; do
        ((COUNT++))
        PERCENT=$(( COUNT * 100 / TOTAL ))

        echo "$PERCENT"
        echo "XXX"
        echo "────────────────────────────────────────"
        echo "$(TXT extracting): $COUNT / $TOTAL files"
        echo "XXX"
    done | dialog --backtitle "$BACKTITLE" \
                  --title "$(TXT step_extract_pack)" \
                  --gauge "$(TXT extracting)" 9 60 0
}


# ─────────────────────────────────────────
# 🔁 Déroulement de l'installation
# ─────────────────────────────────────────

update_steps "backup"
backup_switch_data
sleep 2

update_steps "remove"
remove_old_installations
sleep 2

update_steps "install"
install_new_pack
sleep 2

update_steps "restore"
restore_switch_data
sleep 2

update_steps "cleanup"
ask_zip_backup

update_steps

post_install_prompt


##############################################################
# 🔄 Proposition de mise à jour des émulateurs
##############################################################

dialog --backtitle "$BACKTITLE" \
       --title "$(TXT update_emu_title)" \
       --yes-label "$(TXT yes)" \
       --no-label "$(TXT no)" \
       --yesno "\n$(TXT update_emu_ask)" 8 70 2>&1 >/dev/tty

if [[ $? -eq 0 ]]; then
    dialog --backtitle "$BACKTITLE" \
           --infobox "\n$(TXT update_emu_running)" 5 60
    sleep 1

    clear
    curl -fsSL --retry 3 https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/appimage_updater.sh | bash
fi


printf "%b" "\n$(TXT finished_full)" | \
dialog --backtitle "$BACKTITLE" \
           --title "$(TXT finished_title)" \
           --ok-label "$(TXT ok)" \
           --msgbox "$(cat)" 39 86

curl http://127.0.0.1:1234/reloadgames
clear
reset
exit 0



