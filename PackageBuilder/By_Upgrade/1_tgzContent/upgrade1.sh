#!/bin/sh

PACK_NAME="dummy"

sleep 5
cd /var/upgrade
echo $(date +"%d/%m/%y %H:%M:%S") "${PACK_NAME}_Installer.sh launching..." >> /var/log/${PACK_NAME}.log
./${PACK_NAME}_Installer.sh >> /var/log/${PACK_NAME}.log 2>&1
retval=$?;
sleep 5
if [ $retval ];then
   echo $(date +"%d/%m/%y %H:%M:%S") "Cleaning upgrade files and folders." >> /var/log/${PACK_NAME}.log
   rm -rf /var/upgrade/*
   rmdir  /var/upgrade/
   rm -f  /var/upgrade_download/*
   rmdir  /var/upgrade_download/
   rm -f  /tmp/active_upgrade
   rm -f  /etc/.fw_is_updating
fi

echo $(date +"%d/%m/%y %H:%M:%S") "\"${PACK_NAME}\" package installation done." >> /var/log/${PACK_NAME}.log

cat /var/log/${PACK_NAME}.log >> /proto/SxM_webui/extras/packs/${PACK_NAME}.log
rm -f /var/log/${PACK_NAME}.log

exit 0
