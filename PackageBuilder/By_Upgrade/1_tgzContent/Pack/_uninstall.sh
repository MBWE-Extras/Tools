#!/bin/sh
echo $(date +"%d/%m/%y %H:%M:%S") "Uninstalling package pack 1.0 ..."
sleep 3
rm -rf /proto/SxM_webui/extras/packs/pack
echo $(date +"%d/%m/%y %H:%M:%S") "Uninstall package pack 1.0 complete"
exit 0
