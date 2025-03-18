#!/bin/bash
if [ ! -t 1 ]; then
    echo "No interactive terminal detected. Opening new terminal..."
    xterm -- bash -c "bash /tmp/scripttb.sh; exec bash"
    exit 0
fi

echo "Add script to temp then execute"
rm /tmp/script.sh 2>/dev/null
curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/launch-toolbox.sh -o /tmp/scripttb.sh
dos2unix /tmp/scripttb.sh 2>/dev/null

# Exécution du script dans le terminal actuel si interactif
bash /tmp/scripttb.sh
