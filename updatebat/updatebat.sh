#!/usr/bin/env bash
BACKTITLE="Batocera Upgrade Utility"
MIRROR_ROOT="https://mirrors.o2switch.fr/batocera/x86_64/stable/"
MINSIZE_GIB=3
USERDATA="/userdata"
UP_FILE="/userdata/system/upgrade/upgrade.tar"

# ─── Espace libre ────────────────────────────────────────────────────────────
FREE_GIB=$(df -BG --output=avail "$USERDATA" | tail -1 | tr -dc '0-9')
(( FREE_GIB < MINSIZE_GIB )) && {
    dialog --backtitle "$BACKTITLE" --title "Espace disque insuffisant" \
           --msgbox "Il reste ${FREE_GIB} Gio dans ${USERDATA} (≥ ${MINSIZE_GIB} Gio requis)." 8 60
    clear; exit 1; }

# ─── Liste des versions ≥ 31 ─────────────────────────────────────────────────
versions=$(curl -s "$MIRROR_ROOT" | grep -oP '(?<=href=")[0-9]+/' |
           tr -d '/' | awk '$1>=31' | sort -n)
[[ -z $versions ]] && {
    dialog --backtitle "$BACKTITLE" --msgbox "Aucune version ≥ 31 disponible." 6 40
    clear; exit 1; }

MENU_ITEMS=(); for v in $versions; do MENU_ITEMS+=("$v" "Mettre à jour vers Batocera v$v"); done
CHOIX=$(dialog --backtitle "$BACKTITLE" \
               --title "Mise à jour (espace libre : ${FREE_GIB} Gio)" \
               --menu  "Choisissez la version :" 15 70 10 "${MENU_ITEMS[@]}" \
               3>&1 1>&2 2>&3)
ret=$?; clear
[[ $ret -ne 0 || -z $CHOIX ]] && { echo "Annulé."; exit; }

URL="${MIRROR_ROOT}${CHOIX}/"

# ─── Lancement de la gauge (coprocess) ───────────────────────────────────────
coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                    --cancel-label "Annuler" --gauge "Initialisation…" 10 70 0; }
exec 4>&"${DLG[1]}"

# ─── Fonction de nettoyage si annulation ─────────────────────────────────────
stop_upgrade_cleanup () {
    kill "$UP_PID" 2>/dev/null
    exec 4>&-; wait "$DLG_PID" 2>/dev/null; clear
    rm -f "$UP_FILE"
    dialog --backtitle "$BACKTITLE" --title "Annulé" \
           --msgbox "Mise à jour interrompue par l’utilisateur.\nFichier partiel supprimé." 8 60
    clear; exit 0
}

# ─── Exécution de batocera-upgrade, sortie captée via un pipe ───────────────
stdbuf -oL -eL batocera-upgrade "$URL" 2>&1 | while IFS= read -r line; do
    # Détecter fermeture de la gauge (= clic Annuler ou ESC)
    if ! kill -0 "${DLG_PID:=${DLG[0]}}" 2>/dev/null; then
        dialog --backtitle "$BACKTITLE" --title "Confirmation" \
               --yesno "Êtes-vous sûr de vouloir annuler la mise à jour ?" 7 50
        [[ $? -eq 0 ]] && stop_upgrade_cleanup
        # sinon on recrée la gauge
        exec 4>&-
        coproc DLG { dialog --backtitle "$BACKTITLE" --title "Téléchargement v${CHOIX}" \
                            --cancel-label "Annuler" --gauge "Reprise…" 10 70 0; }
        exec 4>&"${DLG[1]}"
    fi

    [[ $line =~ stat: ]] && continue   # ignorer messages « stat »

    if [[ $line =~ ([0-9]+)\ of\ ([0-9]+)\ MB\ downloaded\ \.\.\.\ \>\>\>\ ([0-9]+)% ]]; then
        dl=${BASH_REMATCH[1]} ; total=${BASH_REMATCH[2]} ; pct=${BASH_REMATCH[3]}
        printf "%s\nXXX\nTéléchargé : %s / %s MB  |  %s %%\nXXX\n" \
               "$pct" "$dl" "$total" "$pct" >&4
    fi
done &
UP_PID=$!

wait "$UP_PID"
FIN=$?

# ─── Fermeture propre de la gauge ────────────────────────────────────────────
exec 4>&-; wait "$DLG_PID" 2>/dev/null; clear
rm -f "$UP_FILE" 2>/dev/null  # résidu éventuel

# ─── Message final ──────────────────────────────────────────────────────────
if [[ $FIN -eq 0 ]]; then
    dialog --backtitle "$BACKTITLE" --title "Succès" \
           --msgbox "Mise à jour vers v${CHOIX} terminée !" 6 40
else
    dialog --backtitle "$BACKTITLE" --title "Échec" \
           --msgbox "batocera-upgrade s’est terminé avec une erreur." 7 50
fi
clear
