#!/usr/bin/env bash
BACKTITLE="Foclabroc Toolbox"
MIRROR_ROOT="https://mirrors.o2switch.fr/batocera/x86_64/stable/"
MINSIZE_GIB=4
USERDATA="/userdata"
UP_FILE="/userdata/system/upgrade/boot.tar.xz"

# Vérifier espace libre
FREE_GIB=$(df -BG --output=avail "$USERDATA" | tail -1 | tr -dc '0-9')
if (( FREE_GIB < MINSIZE_GIB )); then
    dialog --backtitle "$BACKTITLE" --title "Espace disque insuffisant" \
           --msgbox "Il reste ${FREE_GIB} Gio dans ${USERDATA} (≥ ${MINSIZE_GIB} Gio requis)." 8 60
    clear
    exit 1
fi

# Récupérer versions ≥ 31
versions=$(curl -s "$MIRROR_ROOT" | grep -oP '(?<=href=")[0-9]+/' | tr -d '/' | awk '$1>=31' | sort -n)
if [[ -z $versions ]]; then
    dialog --backtitle "$BACKTITLE" --msgbox "Aucune version ≥ 31 disponible." 6 40
    clear
    exit 1
fi

# Préparer menu
MENU_ITEMS=()
for v in $versions; do
    MENU_ITEMS+=("$v" "Installer Batocera v$v")
done

CHOIX=$(dialog --backtitle "$BACKTITLE" --title "Mise à jour (espace libre : ${FREE_GIB} Gio)" \
        --menu "Choisissez la version :" 15 70 10 "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
ret=$?
clear
if [[ $ret -ne 0 || -z $CHOIX ]]; then
    echo "Annulé."
    exit 0
fi

URL="${MIRROR_ROOT}${CHOIX}/"
LOG="/tmp/upgrade.log"
:> "$LOG"

# Fonction nettoyage si annulation
function stop_upgrade_cleanup() {
    kill "$UP_PID" 2>/dev/null
    kill "$TAIL_PID" 2>/dev/null
    exec 4>&-
    wait "$DLG_PID" 2>/dev/null
    clear
    rm -f "$LOG"
    rm -f "$UP_FILE"
    dialog --backtitle "$BACKTITLE" --title "Annulé" \
           --msgbox "Mise à jour interrompue par l’utilisateur.\nFichier partiel supprimé." 8 60
    clear
    exit 0
}

# Démarrer dialog gauge en coprocess
coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                    --cancel-label "Annuler" --gauge "Initialisation…" 10 70 0; }
exec 4>&"${DLG[1]}"

# Lancer batocera-upgrade avec flush immédiat pour log temps réel
stdbuf -oL -eL batocera-upgrade "$URL" > "$LOG" 2>&1 &
UP_PID=$!

# Lire le log en live et parser les lignes pour mise à jour gauge
tail -n0 -F "$LOG" | \
while IFS= read -r line; do
    [[ $line =~ stat: ]] && continue  # Ignorer les messages stat erreur
    if [[ $line =~ ([0-9]+)\ of\ ([0-9]+)\ MB\ downloaded\ \.\.\.\ \>\>\>\ ([0-9]+)% ]]; then
        downloaded=${BASH_REMATCH[1]}
        total=${BASH_REMATCH[2]}
        pct=${BASH_REMATCH[3]}
        printf "%s\nXXX\nTéléchargé : %s / %s MB  |  %s %%\nXXX\n" "$pct" "$downloaded" "$total" "$pct" >&4
    fi
done &
TAIL_PID=$!

# Surveiller processus et gestion annulation
while :; do
    wait -n "$UP_PID" "$TAIL_PID" 2>/dev/null
    fin=$?

    # Si process upgrade fini, sortir
    if ! kill -0 "$UP_PID" 2>/dev/null; then
        break
    fi

    # Si dialog gauge fermé (annulation)
    if ! kill -0 "$DLG_PID" 2>/dev/null; then
        dialog --backtitle "$BACKTITLE" --title "Confirmation" \
               --yesno "Êtes-vous sûr de vouloir annuler la mise à jour ?" 7 50
        ans=$?
        if [[ $ans -eq 0 ]]; then
            stop_upgrade_cleanup
        else
            # Relancer gauge dialog
            exec 4>&-
            coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                                --cancel-label "Annuler" --gauge "Reprise…" 10 70 0; }
            exec 4>&"${DLG[1]}"
        fi
    fi
done

kill "$TAIL_PID" 2>/dev/null
exec 4>&-
wait "$DLG_PID" 2>/dev/null
clear
rm -f "$LOG"

# Message final
if [[ $fin -eq 0 ]]; then
    dialog --backtitle "$BACKTITLE" --title "Succès" \
           --msgbox "Mise à jour vers v${CHOIX} terminée !" 6 40
else
    dialog --backtitle "$BACKTITLE" --title "Échec" \
           --msgbox "batocera-upgrade s’est terminé avec une erreur." 7 50
fi
clear
