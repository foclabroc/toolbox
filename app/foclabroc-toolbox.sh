#!/bin/bash
echo "Add script to temp then execute"
rm /tmp/script.sh 2>/dev/null
curl -L foclabroc.short.gy/toolbox -o /tmp/script.sh
dos2unix /tmp/script.sh 2>/dev/null 
chmod a+x /tmp/script.sh 2>/dev/null
bash /tmp/script.sh