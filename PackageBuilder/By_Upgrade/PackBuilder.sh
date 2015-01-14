#!/bin/sh

ME_NAME="${0##*/}"                  						# Strip longest match of */ from start
ME_DIR=`echo $((${#0}-${#ME_NAME})) $0 | awk '{print substr($2, 1, $1)}' `  	# Substring from 0 thru pos of filename
ME_BASE="${ME_NAME%.[^.]*}"            						# Strip shortest match of . plus at least one non-dot char from end
ME_EXT=`echo ${#ME_BASE} $ME_NAME | awk '{print substr($2, $1 + 1)}' `	# Substring from len of base thru end

CURDIR=$(pwd)
cd $ME_DIR

#PACK=${PWD#*Upgrade_}								# Method in case of prefix in folder name
PACK=`echo $(pwd) | awk -F/ '{print $NF}'`
VER=$(echo ${PACK#*_} | awk '{gsub("_",".",$0); print}')
FW_VER="01.02.14"
FW_IMG="${PACK}.img"
FW_WDG="upgrd-pkg-1nc.wdg"
FW_ZIP="upgrd-pkg-1nc.zip"

#*******************************
# Encode/Decode IMG File
#*******************************
# usage : FWEncDec $FW_IMG
FWEncDec() {
    if test $# -eq 1; then
       /bin/dd skip=0  count=1 bs=5120 if=$1 of=$1.tmp1 >/dev/null 2>&1
       /bin/dd skip=15 count=1 bs=5120 if=$1 of=$1.tmp2 >/dev/null 2>&1
       cp $1 $1.orig
       /bin/dd seek=0  count=1 bs=5120 if=$1.tmp2 of=$1 >/dev/null 2>&1
       /bin/dd skip=1  seek=1  bs=5120 if=$1.orig of=$1 >/dev/null 2>&1
       cp $1 $1.orig
       /bin/dd seek=15 count=1 bs=5120 if=$1.tmp1 of=$1 >/dev/null 2>&1
       /bin/dd skip=16 seek=16 bs=5120 if=$1.orig of=$1 >/dev/null 2>&1
       rm -f $1.tmp1
       rm -f $1.tmp2
       rm -f $1.orig
    fi
}

case "$1" in
  compress)
    rm -f 8_Sortie/*

    ##### Build wdg file #####
    cd 1_tgzContent
    echo -n $VER > Pack/_version
    find * -exec md5sum "'{}'" \; > ../md5sum.lst
    mv -f ../md5sum.lst md5sum.lst
    find * > ../fileslist
    /bin/tar zvcf ../8_Sortie/$FW_ZIP -T ../fileslist
    rm -f ../fileslist
    rm -f md5sum.lst

    cd ../8_Sortie
    cat ../2_autoscript/autoscript $FW_ZIP > $FW_WDG
    chmod +x $FW_WDG
    rm -f $FW_ZIP
    md5sum $FW_WDG > $FW_WDG.md5

    ##### Compress Firmware #####
    echo ${FW_VER} > ../3_imgContent/fw.ver
    cp -p ../3_imgContent/* .
    /bin/tar zvcf ../$FW_IMG *

    /usr/bin/find . -type f -exec rm -rf {} \; >/dev/null 2>&1
    mv -f ../$FW_IMG ./

    ##### Encode Firmware #####
    FWEncDec $FW_IMG

    MD5SUM=$(cat $FW_IMG | md5sum | cut  -d' ' -f1)
    echo $MD5SUM > $MD5SUM
  ;;
  deflate)
    cd 9_Test
    /usr/bin/find . -type f -exec rm -rf {} \; >/dev/null 2>&1
    cp -f ../8_Sortie/$FW_IMG $FW_IMG

    ##### Decode Firmware #####
    FWEncDec $FW_IMG

    ##### Deflate Firmware #####
    /bin/tar zxf $FW_IMG

    ##### Extract tgz file #####
    /bin/tar zxf $FW_SP -C ./tgz
  ;;
  *)
    echo ""
    echo "$PACK Pack Builder"
    echo "--------------------"
    echo "Syntax:"
    echo "  $0 {compress|deflate}"
    echo ""
    exit 3
  ;;
esac

cd $PWD
