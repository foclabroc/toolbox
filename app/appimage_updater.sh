#!/bin/bash

# ===============================
# LANGUAGE SELECTION
# ===============================
LANG_UI="fr"

select_language() {
    dialog --backtitle "Foclabroc Switch AppImages Updater" \
           --title "Language / Langue" \
		   --ok-label "OK" \
		   --cancel-label "Cancel" \
           --menu "Please select your language / Veuillez choisir la langue :" 12 65 2 \
           fr "Français" \
           en "English" 2> /tmp/lang.choice

    if [[ $? -ne 0 ]]; then
        clear
        exit 0
    fi

    LANG_UI=$(cat /tmp/lang.choice)
    rm -f /tmp/lang.choice
}

tr() {
    case "$LANG_UI:$1" in
        fr:SYS_FILES) echo "Fichiers système" ;;
        en:SYS_FILES) echo "System files" ;;

        fr:SYS_UPDATE) echo "Mise à jour des fichiers système…" ;;
        en:SYS_UPDATE) echo "Updating system files…" ;;

        fr:SYS_DONE) echo "Fichiers système mis à jour" ;;
        en:SYS_DONE) echo "System files updated" ;;

        fr:SYS_FAIL) echo "Échec mise à jour fichiers système" ;;
        en:SYS_FAIL) echo "System files update failed" ;;

        fr:BACKTITLE) echo "Foclabroc Switch AppImages Updater" ;;
        en:BACKTITLE) echo "Foclabroc Switch AppImages Updater" ;;

        fr:ERROR) echo "ERREUR" ;;
        en:ERROR) echo "ERROR" ;;

        fr:ERROR_EMU) echo "NON MIS A JOUR" ;;
        en:ERROR_EMU) echo "NOT UPDATED" ;;

        fr:CONFIRM_TITLE) echo "Switch AppImages Updater" ;;
        en:CONFIRM_TITLE) echo "Switch AppImages Updater" ;;

        fr:CANCEL_LABEL) echo "Annuler" ;;
        en:CANCEL_LABEL) echo "Cancel" ;;

        fr:OK_LABEL) echo "Accepter" ;;
        en:OK_LABEL) echo "OK" ;;

        fr:YES_LABEL) echo "Oui" ;;
        en:YES_LABEL) echo "Yes" ;;

        fr:NO_LABEL) echo "Non" ;;
        en:NO_LABEL) echo "No" ;;

        fr:PROGRESS) echo "Téléchargement en cours..." ;;
        en:PROGRESS) echo "Download in progress..." ;;

        fr:CONFIRM_TEXT) echo "
Voulez-vous mettre à jour les AppImages Switch ?

• Citron
• Eden
• Eden PGO
• Ryujinx" ;;
        en:CONFIRM_TEXT) echo "
Do you want to update Switch AppImages?

• Citron
• Eden
• Eden PGO
• Ryujinx" ;;

        fr:GAUGE_TITLE) echo "Mise à jour des AppImages Switch" ;;
        en:GAUGE_TITLE) echo "Updating Switch AppImages" ;;

        fr:GAUGE_TEXT) echo "Téléchargement des fichiers…" ;;
        en:GAUGE_TEXT) echo "Downloading files…" ;;

        fr:FINAL_TITLE) echo "Mise à jour terminée" ;;
        en:FINAL_TITLE) echo "Update completed" ;;

        fr:DOWNLOAD_DONE) echo "Téléchargement terminé" ;;
        en:DOWNLOAD_DONE) echo "Download completed" ;;

        fr:UPDATE_RESULT) echo "Résultat mise à jour :" ;;
        en:UPDATE_RESULT) echo "Update Result :" ;;

        *) echo "$1" ;;
    esac
}

select_language
BACKTITLE="$(tr BACKTITLE)"

# ===============================
# PATHS
# ===============================
SWITCH_APPIMAGES="/userdata/system/switch/appimages-updater-temp"
SWITCH_APPIMAGES_FINAL="/userdata/system/switch/appimages"
TEMP_DIR="/userdata/system/switch/appimages-updater-temp"
LOG_DIR="/userdata/system/switch/appimages-updater-temp"

LOG_FILE="$LOG_DIR/update.log"
VERSIONS_FILE="$TEMP_DIR/versions.tmp"
STATUS_FILE="$TEMP_DIR/status.tmp"

mkdir -p "$SWITCH_APPIMAGES" "$TEMP_DIR" "$LOG_DIR"
> "$LOG_FILE"
> "$VERSIONS_FILE"
> "$STATUS_FILE"

# ===============================
# LOG
# ===============================
log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# ===============================
# STEP DOWNLOAD (GAUGE PAR ÉTAPES)
# ===============================
wget_step() {
    local url="$1"
    local dest="$2"
    local label="$3"

    log "Downloading $label"

    local spinner=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    local i=0

    wget --tries=3 --timeout=10 --connect-timeout=5 \
         "$url" -O "$dest" 2>>"$LOG_FILE" &
    pid=$!

    while kill -0 $pid 2>/dev/null; do
        echo "XXX"
        echo "$GLOBAL_PERCENT"
        echo "$(tr GAUGE_TEXT)"
        echo "======================="
        echo " "
        echo "-->[${label}.AppImage]"
        echo "--> ${spinner[$i]} $(tr PROGRESS)"
        echo "XXX"

        i=$(( (i + 1) % ${#spinner[@]} ))
        sleep 0.15
    done

    wait $pid || return 1
    chmod +x "$dest"
    return 0
}

deploy_if_valid() {
    local src="$1"
    local name
    local size_mb

    name=$(basename "$src")

    if [[ ! -f "$src" ]]; then
        log "ERROR deploy: $name not found"
        return 1
    fi

    size_mb=$(du -m "$src" | cut -f1)

    if (( size_mb < 20 )); then
        log "ERROR deploy: $name too small (${size_mb}MB) – skipped"
        return 1
    fi

    mkdir -p "$SWITCH_APPIMAGES_FINAL"
    mv -f "$src" "$SWITCH_APPIMAGES_FINAL/$name"

    log "Deployed $name to final folder (${size_mb}MB)"
    return 0
}

# ===============================
# UPDATE SYSTEM FILES
# ===============================
install_new_pack() {

    log "Starting system files update pack"

    PACK_URL="https://github.com/foclabroc/New-batocera-switch/archive/refs/heads/main.zip"
    PACK_ZIP="/userdata/tmpf/pack.zip"
    EXTRACT_DIR="/userdata/tmpf/new_switch_pack"

    mkdir -p /userdata/tmpf

    echo "XXX"
    echo "$GLOBAL_PERCENT"
    echo "$(tr GAUGE_TEXT)"
    echo "======================="
    echo " "
    echo "-->$(tr SYS_UPDATE)"
    echo "XXX"

    wget -q -O "$PACK_ZIP" "$PACK_URL" || {
        log "ERROR system pack download failed"
        echo "STATUS_SYS=ERREUR" >> "$STATUS_FILE"
        return
    }

    if [[ ! -s "$PACK_ZIP" ]]; then
        log "ERROR system pack zip empty"
        echo "STATUS_SYS=ERREUR" >> "$STATUS_FILE"
        return
    fi

    rm -rf "$EXTRACT_DIR"
    mkdir -p "$EXTRACT_DIR"
    unzip -o "$PACK_ZIP" -d "$EXTRACT_DIR" >>"$LOG_FILE" 2>&1

    ROOT_DIR=$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)

    [[ -d "$ROOT_DIR" ]] || {
        log "ERROR system pack extraction failed"
        echo "STATUS_SYS=ERREUR" >> "$STATUS_FILE"
        return
    }

    shopt -s dotglob nullglob
    cp -r "$ROOT_DIR"/* /userdata/ >>"$LOG_FILE" 2>&1
    shopt -u dotglob nullglob

    log "System files copied"

    # --- XMLSTARLET SETUP ---
    XMLSTARLET_DIR="/userdata/system/switch/extra"
    XMLSTARLET_BIN="$XMLSTARLET_DIR/xmlstarlet"
    XMLSTARLET_SYMLINK="/usr/bin/xmlstarlet"

    if [ -f "$XMLSTARLET_BIN" ]; then
        chmod +x "$XMLSTARLET_BIN"
        ln -sf "$XMLSTARLET_BIN" "$XMLSTARLET_SYMLINK"
        log "xmlstarlet ready"
    fi

    gamelist_file="/userdata/roms/ports/gamelist.xml"
    gamelist_file2="/userdata/roms/switch/gamelist.xml"

    [[ -f "$gamelist_file" ]] || echo '<?xml version="1.0"?><gameList></gameList>' > "$gamelist_file"
    [[ -f "$gamelist_file2" ]] || echo '<?xml version="1.0"?><gameList></gameList>' > "$gamelist_file2"

    remove_game_by_path() {
        xmlstarlet ed -L -d "/gameList/game[path='$2']" "$1" 2>/dev/null
    }

    log "Updating gamelists"

    # Supprimer anciennes entrées
    remove_game_by_path "$gamelist_file" "./updateryujinx.sh"
    remove_game_by_path "$gamelist_file" "./updateryujinxavalonia.sh"
    remove_game_by_path "$gamelist_file" "./batocera-switch-installer.sh"
    remove_game_by_path "$gamelist_file" "./Suyu Qlauncher.sh"
    remove_game_by_path "$gamelist_file" "./batocera-switch-updater.sh"
    remove_game_by_path "$gamelist_file" "./Switch Updater.sh"
    remove_game_by_path "$gamelist_file" "./updateyuzuEA.sh"
    remove_game_by_path "$gamelist_file" "./updateyuzu.sh"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file" "./ryujinx_config.sh"
    # Ajouter Ryujinx Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./ryujinx_config.sh" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "Ryujinx Config App" \
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
        "$gamelist_file"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file" "./yuzu_config.sh"
    # Ajouter Eden Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./yuzu_config.sh" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "Eden Config App" \
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
        "$gamelist_file"

    # Supprimer entrée avant création
    remove_game_by_path "$gamelist_file" "./citron_config.sh"
    # Ajouter Citron Config
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./citron_config.sh" \
        -s "/gameList/game[last()]" -t elem -n "name" -v "Citron Config App" \
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
        "$gamelist_file"

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
    remove_game_by_path "$gamelist_file2" "./_Switch-Home-menu.xci"
    # Ajouter Qlauncher
    xmlstarlet ed -L \
        -s "/gameList" -t elem -n "game" -v "" \
        -s "/gameList/game[last()]" -t elem -n "path" -v "./_Switch-Home-menu.xci" \
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

    rm -f "/userdata/README.md"
    rm -rf "/userdata/tmpf"

    log "System pack installation finished"
    echo "STATUS_SYS=OK" >> "$STATUS_FILE"
}

# ===============================
# UPDATE CITRON
# ===============================
update_citron() {
    local page tag tag_decoded version url dest

    log "Checking Citron GitHub tags (stable only)"

    page=$(curl -Ls "https://github.com/pkgforge-dev/Citron-AppImage/tags" 2>>"$LOG_FILE")

    if [[ -z "$page" ]]; then
        log "ERROR Citron: unable to download tags page"
        echo "STATUS_CITRON=ERREUR" >> "$STATUS_FILE"
        return
    fi

    # Dernier tag stable (URL encodé)
    tag=$(echo "$page" |
        grep -Eo '/pkgforge-dev/Citron-AppImage/releases/tag/[^"]+' |
        grep -v nightly |
        head -n1 |
        sed 's#.*/##')

    if [[ -z "$tag" ]]; then
        log "ERROR Citron: no stable tag found"
        echo "STATUS_CITRON=ERREUR" >> "$STATUS_FILE"
        return
    fi

    # Décodage %40 → @
    tag_decoded="${tag//%40/@}"

    # Version = avant @
    version="${tag_decoded%%@*}"

    url="https://github.com/pkgforge-dev/Citron-AppImage/releases/download/$tag_decoded/Citron-$version-anylinux-x86_64.AppImage"
    dest="$SWITCH_APPIMAGES/citron-emu.AppImage"

    log "Detected stable Citron tag: $tag_decoded"
    log "Detected Citron version: $version"
    log "Downloading: $url"

    if wget_step "$url" "$dest" "citron-emu" && deploy_if_valid "$dest"; then
        echo "STATUS_CITRON=OK" >> "$STATUS_FILE"
        echo "CITRON_VERSION=$version" >> "$VERSIONS_FILE"
    else
        log "ERROR Citron: download or deploy failed"
        echo "STATUS_CITRON=ERREUR" >> "$STATUS_FILE"
    fi
}

# ===============================
# UPDATE EDEN
# ===============================
update_eden() {
    local json release url dest

    log "Checking Eden latest release"

    json=$(curl -fsL "https://api.github.com/repos/eden-emulator/Releases/releases/latest" 2>>"$LOG_FILE")

    if [[ -z "$json" ]]; then
        log "ERROR Eden: GitHub API unreachable"
        echo "STATUS_EDEN=ERREUR" >> "$STATUS_FILE"
        return
    fi

    release=$(echo "$json" |
        grep -Eo '"tag_name": *"[^"]+"' |
        sed -E 's/.*"([^"]+)".*/\1/')

    if [[ -z "$release" ]]; then
        log "ERROR Eden: tag_name not found"
        echo "STATUS_EDEN=ERREUR" >> "$STATUS_FILE"
        return
    fi

    url="https://github.com/eden-emulator/Releases/releases/download/$release/Eden-Linux-$release-amd64-gcc-standard.AppImage"
    dest="$SWITCH_APPIMAGES/eden-emu.AppImage"

    if wget_step "$url" "$dest" "eden-emu" && deploy_if_valid "$dest"; then
        echo "STATUS_EDEN=OK" >> "$STATUS_FILE"
        echo "EDEN_VERSION=$release" >> "$VERSIONS_FILE"
    else
        echo "STATUS_EDEN=ERREUR" >> "$STATUS_FILE"
    fi
}

# ===============================
# UPDATE EDEN PGO
# ===============================
update_eden_pgo() {
    local release url dest

    release=$(grep '^EDEN_VERSION=' "$VERSIONS_FILE" | cut -d= -f2)

    if [[ -z "$release" ]]; then
        log "ERROR Eden-PGO: Eden version missing"
        echo "STATUS_EDEN_PGO=ERREUR" >> "$STATUS_FILE"
        return
    fi

    url="https://github.com/eden-emulator/Releases/releases/download/$release/Eden-Linux-$release-amd64-clang-pgo.AppImage"
    dest="$SWITCH_APPIMAGES/eden-pgo.AppImage"

    if wget_step "$url" "$dest" "eden-pgo" && deploy_if_valid "$dest"; then
        echo "STATUS_EDEN_PGO=OK" >> "$STATUS_FILE"
        echo "EDEN_PGO_VERSION=$release" >> "$VERSIONS_FILE"
    else
        echo "STATUS_EDEN_PGO=ERREUR" >> "$STATUS_FILE"
    fi
}

# ===============================
# UPDATE RYUJINX
# ===============================
update_ryujinx() {
    local page release url dest

    log "Checking Ryujinx Canary version"

    page=$(curl -fsL "https://release-monitoring.org/project/377871/" 2>>"$LOG_FILE")

    if [[ -z "$page" ]]; then
        log "ERROR Ryujinx: unable to fetch version page"
        echo "STATUS_RYUJINX=ERREUR" >> "$STATUS_FILE"
        return
    fi

    release=$(echo "$page" |
        grep -Eo 'Canary-[0-9]+\.[0-9]+\.[0-9]+' |
        sort -V | tail -n1 | cut -d- -f2)

    if [[ -z "$release" ]]; then
        log "ERROR Ryujinx: version parsing failed"
        echo "STATUS_RYUJINX=ERREUR" >> "$STATUS_FILE"
        return
    fi

    url="https://git.ryujinx.app/api/v4/projects/68/packages/generic/Ryubing-Canary/$release/ryujinx-canary-$release-x64.AppImage"
    dest="$SWITCH_APPIMAGES/ryujinx-emu.AppImage"

    if wget_step "$url" "$dest" "ryujinx-emu" && deploy_if_valid "$dest"; then
        echo "STATUS_RYUJINX=OK" >> "$STATUS_FILE"
        echo "RYUJINX_VERSION=$release" >> "$VERSIONS_FILE"
    else
        echo "STATUS_RYUJINX=ERREUR" >> "$STATUS_FILE"
    fi
}

# ===============================
# RUN UPDATE
# ===============================
run_update() {

GLOBAL_PERCENT=0

(
    install_new_pack
    GLOBAL_PERCENT=20

    update_citron
    GLOBAL_PERCENT=40

    update_eden
    GLOBAL_PERCENT=60

    update_eden_pgo
    GLOBAL_PERCENT=80

    update_ryujinx
    GLOBAL_PERCENT=100

) | dialog --backtitle "$BACKTITLE" \
           --title "$(tr GAUGE_TITLE)" \
           --gauge "\n$(tr GAUGE_TEXT)" 12 60 0

    touch "$STATUS_FILE" "$VERSIONS_FILE"
    set -a
    source "$STATUS_FILE"
    source "$VERSIONS_FILE"
    set +a

    [[ "$STATUS_SYS" == "OK" ]] \
        && SYS_LINE="$(tr SYS_FILES) : OK" \
        || SYS_LINE="$(tr SYS_FILES) : $(tr SYS_FAIL)"

    [[ "$STATUS_CITRON" == "OK" ]] \
        && CITRON_LINE="Citron       : OK ---->(${CITRON_VERSION})" \
        || CITRON_LINE="Citron       : $(tr ERROR) citron-emu.AppImage $(tr ERROR_EMU)"

    [[ "$STATUS_EDEN" == "OK" ]] \
        && EDEN_LINE="Eden         : OK ---->(${EDEN_VERSION})" \
        || EDEN_LINE="Eden         : $(tr ERROR) eden-emu.AppImage $(tr ERROR_EMU)"

    [[ "$STATUS_EDEN_PGO" == "OK" ]] \
        && EDEN_PGO_LINE="Eden-PGO     : OK ---->(${EDEN_PGO_VERSION})" \
        || EDEN_PGO_LINE="Eden-PGO     : $(tr ERROR) eden-pgo.AppImage $(tr ERROR_EMU)"

    [[ "$STATUS_RYUJINX" == "OK" ]] \
        && RYUJINX_LINE="Ryujinx      : OK ---->(${RYUJINX_VERSION})" \
        || RYUJINX_LINE="Ryujinx      : $(tr ERROR) ryujinx-emu.AppImage $(tr ERROR_EMU)"

    dialog --backtitle "$BACKTITLE" \
           --title "$(tr FINAL_TITLE)" \
           --ok-label "$(tr OK_LABEL)" \
           --no-collapse \
           --msgbox "$(cat <<EOF

$(tr UPDATE_RESULT)

$SYS_LINE

$CITRON_LINE
$EDEN_LINE
$EDEN_PGO_LINE
$RYUJINX_LINE

Logs : $LOG_FILE
EOF
)" 17 70

exit 0
}

# ===============================
# CONFIRMATION
# ===============================
dialog --backtitle "$BACKTITLE" \
       --title "$(tr CONFIRM_TITLE)" \
       --yes-label "$(tr YES_LABEL)" \
       --no-label "$(tr NO_LABEL)" \
       --yesno "$(tr CONFIRM_TEXT)" 13 60

case $? in
    0) run_update ;;
    *) clear; exit 0;;
esac
