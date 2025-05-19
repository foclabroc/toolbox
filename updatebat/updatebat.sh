#!/usr/bin/env bash

MIRROR_ROOT="https://mirrors.o2switch.fr/batocera/x86_64/stable/"
MINSIZE_GIB=3
USERDATA="/userdata"

# ───────────────────────────────── Vérif. espace libre ──────────────────────
# Récupère l’espace libre en Gio (partie entière)
FREE_GIB=$(df -BG --output=avail "$USERDATA" | tail -1 | tr -dc '0-9')

if (( FREE_GIB < MINSIZE_GIB )); then
    dialog --backtitle "Foclabroc Toolbox" --title "Espace disque insuffisant" \
           --msgbox "Il ne reste que ${FREE_GIB} Gio libres dans ${USERDATA}.\n\
Au moins ${MINSIZE_GIB} Gio sont requis pour mettre à jour Batocera.\n\
Libérez de l’espace puis réessayez." 9 60
    clear
    exit 1
fi
# ───────────────────────────── Liste des versions dispo ─────────────────────
versions=$(curl -s "${MIRROR_ROOT}" \
           | grep -oP '(?<=href=")[0-9]+/' \
           | tr -d '/' \
           | awk '$1 >= 31' \
           | sort -n)

if [[ -z $versions ]]; then
    dialog --backtitle "Foclabroc Toolbox" --title "Erreur" --msgbox \
           "Aucune version ≥ 31 trouvée sur le miroir." 7 50
    clear
    exit 1
fi

# Construit le menu Dialog
MENU_ITEMS=()
for v in $versions; do
    MENU_ITEMS+=("$v" "Mettre à jour vers Batocera v$v (x86_64, stable)")
done

CHOIX=$(dialog --clear \
        --backtitle "Foclabroc Toolbox" \
        --title "Mise à jour Batocera (espace libre : ${FREE_GIB} Gio)" \
        --menu "Choisissez la version à installer :" 15 70 10 \
        "${MENU_ITEMS[@]}" \
        3>&1 1>&2 2>&3)

ret=$?
clear

if [[ $ret -eq 0 && -n $CHOIX ]]; then
    URL="${MIRROR_ROOT}${CHOIX}/"
    echo -e "\nEspace libre détecté : ${FREE_GIB} Gio"
    echo -e "Lancement de la mise à jour vers v${CHOIX}…"
    echo "Commande exécutée : batocera-upgrade ${URL}"
    batocera-upgrade "${URL}"
    echo -e "\nMise à jour terminée."
else
    echo "Opération annulée."
fi
