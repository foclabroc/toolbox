#!/bin/bash
echo "Add script to temp then execute"
rm /tmp/toolbox 2>/dev/null
wget -q --tries=30 --no-check-certificate --no-cache --no-cookies -O /tmp/toolbox https://github.com/foclabroc/toolbox/blob/main/app/foclabroc-toolbox.sh
dos2unix /tmp/toolbox 2>/dev/null 
chmod 777 /tmp/toolbox 2>/dev/null
bash /tmp/toolbox