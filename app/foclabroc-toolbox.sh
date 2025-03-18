#!/bin/bash

echo "Add script to temp then execute"
rm /tmp/script.sh 2>/dev/null
curl -L https://raw.githubusercontent.com/foclabroc/toolbox/refs/heads/main/app/launch-toolbox.sh -o /tmp/scripttb.sh
dos2unix /tmp/scripttb.sh 2>/dev/null 
bash /tmp/scripttb.sh
