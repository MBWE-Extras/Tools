#!/bin/sh

ME_NAME="${0##*/}"                  						# Strip longest match of */ from start
ME_DIR=`echo $((${#0}-${#ME_NAME})) $0 | awk '{print substr($2, 1, $1)}' `  	# Substring from 0 thru pos of filename
ME_BASE="${ME_NAME%.[^.]*}"            						# Strip shortest match of . plus at least one non-dot char from end
ME_EXT=`echo ${#ME_BASE} $ME_NAME | awk '{print substr($2, $1 + 1)}' `	# Substring from len of base thru end

PACK_NAME="${ME_NAME%_[^_]*}"

CURDIR=$(pwd)
FW_STATUS_FILE=/var/upgrade_download/fwud_status

Follow() {
   if [ -n "$1" ]; then
      echo ${1}%${2} > $FW_STATUS_FILE
   fi
   echo -e $(date +"%d/%m/%y %H:%M:%S") $2
   sleep 3
}

Follow "10" "It starts..."

Follow "15" "Check type of My Book World Edition"
if [ !  -d /proto/SxM_webui ];then
   Follow "" "ERROR: This installer is only for Mybook WhiteLight device, please use the $PACK_NAME installer for your device."
   exit 1
fi

Follow "20" "Check OPTWARE installed"
if [ ! -f /opt/bin/ipkg ] ;  then
   Follow "" "ERROR: OPTWARE not installed. Please re-install EXTRAS package first."
   exit 2
fi

Follow "25" "Check EXTRAS installed"
if [ ! -d /proto/SxM_webui/extras/packs ] ;  then
   Follow "" "ERROR: EXTRAS not installed. Please install EXTRAS package first before its sub-packages."
   exit 3
fi

Follow "30" "Create folder package \"$PACK_NAME\""
if [ ! -d /proto/SxM_webui/extras/packs/${PACK_NAME} ] ;  then
   mkdir /proto/SxM_webui/extras/packs/${PACK_NAME}
fi

Follow "40" "Copy useful package \"$PACK_NAME\" files"
mv /var/upgrade/Pack/* /proto/SxM_webui/extras/packs/${PACK_NAME}

for i in 50 60 70 80 90
do
   Follow $i "It's the next $i%..."
done
cd $CURDIR

Follow "100" "\"$PACK_NAME\" Installation Complete"
