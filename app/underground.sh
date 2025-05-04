#!/bin/bash
clear

# 🔐 Demande de mot de passe via dialog
mdp=$(dialog --no-cancel --passwordbox "Mot de passe nécessaire :" 8 40 2>&1 >/dev/tty)

if [[ $? -ne 0 || -z "$mdp" ]]; then
    clear
    echo "Erreur retour menu."
    sleep 2
    exit 0
fi

menu_script=$(curl -fsSL "https://secret.batoaddons.app/scripts.php?pw=${password}&script=menu.sh")

# ❌ Vérification de l’échec de récupération
if [[ $? -ne 0 || -z "$menu_script" ]]; then
    clear
    echo "❌ Access denied or failed to retrieve menu script."
    sleep 3
    exit 1
fi

# 🔐 Export du mot de passe pour les scripts enfants
export PASSWORD="$password"

# ▶️ Exécution du script récupéré dans un sous-shell
bash -c "$menu_script"

