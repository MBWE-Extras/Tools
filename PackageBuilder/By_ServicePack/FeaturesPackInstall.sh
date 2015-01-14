#!/bin/sh

ME_NAME="${0##*/}"                  						# Strip longest match of */ from start
ME_DIR=`echo $((${#0}-${#ME_NAME})) $0 | awk '{print substr($2, 1, $1)}' `  	# Substring from 0 thru pos of filename
ME_BASE="${ME_NAME%.[^.]*}"            						# Strip shortest match of . plus at least one non-dot char from end
ME_EXT=`echo ${#ME_BASE} $ME_NAME | awk '{print substr($2, $1 + 1)}' `		# Substring from len of base thru end

FW_SP="sp.tgz"
FW_DL="/var/upgrade_download"
FW_IMG="wdhxnc-99.99.99.sp99.img"

CURDIR=$(pwd)
cd $ME_DIR

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

    ##### Build tgz file #####
    rm -rf $FW_DL
    mkdir -p $FW_DL
    cp 1_tgzContent/* $FW_DL
    /bin/tar zvcf 8_Sortie/$FW_SP $FW_DL/*
    rm -rf $FW_DL

#    tar zvcf 8_Sortie/$FW_SP .
#    /bin/tar cvf - . | gzip -9 > 8_Sortie/$FW_SP

    cd 8_Sortie
    md5sum $FW_SP > $FW_SP.md5

    ##### Compress Firmware #####
    cp -p ../2_imgContent/* .
    /bin/tar zvcf ../$FW_IMG *
    /usr/bin/find . -type f -exec rm -rf {} \; >/dev/null 2>&1
    mv -f ../$FW_IMG ./

    ##### Encode Firmware #####
    FWEncDec $FW_IMG
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
    echo "FeaturesPack Manager"
    echo "--------------------"
    echo "Syntax:"
    echo "  $0 {compress|deflate}"
    echo ""
    exit 3
  ;;
esac

cd $PWD
