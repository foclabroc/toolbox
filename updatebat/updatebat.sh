#!/usr/bin/env bash

BACKTITLE="Foclabroc Toolbox"
MIRROR_ROOT="https://mirrors.o2switch.fr/batocera/x86_64/stable/"
MINSIZE_GIB=4
USERDATA="/userdata"
UP_FILE="/userdata/system/upgrade/upgrade.tar"

#──────── Espace libre ────────
FREE_GIB=$(df -BG --output=avail "$USERDATA" | tail -1 | tr -dc '0-9')
(( FREE_GIB < MINSIZE_GIB )) && {
    dialog --backtitle "$BACKTITLE" --title "Espace disque insuffisant" \
           --msgbox "Il reste ${FREE_GIB} Gio dans ${USERDATA} (≥ ${MINSIZE_GIB} Gio requis)." 8 60 2>&1 >/dev/tty
    clear; exit 1; }

#──────── Liste versions ──────
versions=$(curl -s "$MIRROR_ROOT" | grep -oP '(?<=href=")[0-9]+/' | tr -d '/' | awk '$1>=31' | sort -n)
[[ -z $versions ]] && { dialog --backtitle "$BACKTITLE" --msgbox "Aucune version ≥ 31." 6 40 2>&1 >/dev/tty; clear; exit 1; }

MENU_ITEMS=(); for v in $versions; do MENU_ITEMS+=("$v" "Installer Batocera v$v"); done
CHOIX=$(dialog --backtitle "$BACKTITLE" --title "Mise à jour (espace libre : ${FREE_GIB} Gio)" \
        --menu "Choisissez la version :" 24 70 10 "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
ret=$?; clear
[[ $ret -ne 0 || -z $CHOIX ]] && { echo "Annulé."; exit; }

URL="${MIRROR_ROOT}${CHOIX}/"
LOG="/tmp/upgrade.log"; :> "$LOG"

#──────── Fonction d’arrêt et nettoyage ────────────────
function stop_upgrade_cleanup() {
    kill "$UP_PID" 2>/dev/null
    kill "$TAIL_PID" 2>/dev/null
    exec 4>&-     # ferme gauge
    wait "$DLG_PID" 2>/dev/null
    clear
    rm -f "$LOG"
    rm -f "$UP_FILE"
    dialog --backtitle "$BACKTITLE" --title "Annulé" \
           --msgbox "Mise à jour interrompue par l’utilisateur.\nFichier partiel supprimé." 8 60 2>&1 >/dev/tty
    clear
    exit 0
}

#──────── Gauge en coprocess ──────
coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                    --cancel-label "Annuler" --gauge "Initialisation…" 10 70 0; }
exec 4>&"${DLG[1]}"

# Lance batocera-upgrade
batocera-upgrade "$URL" &> "$LOG" &
UP_PID=$!

# Suivi log vers gauge
tail -n0 -F "$LOG" | \
while IFS= read -r line; do
    [[ $line =~ ([0-9]{1,3})%\ +[0-9.]+[MKG]?B/s\ +[0-9:]{8} ]] || continue
    pct=${BASH_REMATCH[1]}
    speed=$(awk '{for(i=1;i<=NF;i++) if($i~/[0-9.]+[MK]B\/s/) {print $i; exit}}' <<<"$line")
    eta=$(awk '{print $(NF-1)}' <<<"$line")
    printf "%s\nXXX\nTéléchargement : %s %% | %s | ETA %s\nXXX\n" "$pct" "$pct" "$speed" "$eta" >&4
done &
TAIL_PID=$!

#──────── Boucle de surveillance avec gestion annulation ─────
while :; do
    wait -n "$UP_PID" "${DLG_PID:=${DLG[0]}}"
    fin=$?
    if ! kill -0 "$UP_PID" 2>/dev/null; then
        # Upgrade fini (succès ou erreur)
        break
    fi

    # La gauge s'est fermée => annulation demandée
    if ! kill -0 "$DLG_PID" 2>/dev/null; then
        # Demande confirmation annulation
        dialog --backtitle "$BACKTITLE" --title "Confirmation" \
            --yesno "Êtes-vous sûr de vouloir annuler la mise à jour ?" 7 50 2>&1 >/dev/tty
        ans=$?
        if [[ $ans -eq 0 ]]; then
            stop_upgrade_cleanup
        else
            # relance la gauge
            exec 4>&-
            coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                                --cancel-label "Annuler" --gauge "Reprise…" 10 70 0; }
            exec 4>&"${DLG[1]}"
            continue
        fi
    fi
done

#──────── Nettoyage normal ─────
kill "$TAIL_PID" 2>/dev/null
exec 4>&-
wait "$DLG_PID" 2>/dev/null
clear
rm -f "$LOG"

if [[ $fin -eq 0 ]]; then
    dialog --backtitle "$BACKTITLE" --title "Succès" \
           --msgbox "Mise à jour vers v${CHOIX} terminée !" 6 40 2>&1 >/dev/tty
else
    dialog --backtitle "$BACKTITLE" --title "Échec" \
           --msgbox "batocera-upgrade s’est terminé avec une erreur." 7 50 2>&1 >/dev/tty
fi
clear
