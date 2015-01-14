#!/bin/bash
# J J Larkworthy
# 9-May-2007
# Script to recover the components of a NAS upgrade from a received diference 
# file and the stored images.
#
# This script runs on the NAS to copy the stored files modify their contents
# based on the downloaded package file.

LIB=/var/lib

cd /var/upgrade

if  test -f rootfs.xdt3 
then 
	# running a differential upgrade so check for missing files
	if test ! -f stage1.wrapped  ; then cp ${LIB}/stage1.wrapped . ; fi
	if test ! -f u-boot.wrapped  ; then cp ${LIB}/u-boot.wrapped . ; fi
	if test ! -f rootfs.arm.ext2  ; then cp ${LIB}/rootfs.arm.ext2 . ; fi
	if test ! -f uImage  ; then cp ${LIB}/uImage . ; fi
	if test ! -f uImage.1  ; then cp ${LIB}/uImage.1 . ; fi
	if test ! -f uUpgradeRootfs  ; then cp ${LIB}/uUpgradeRootfs . ; fi
	
	#need more swap for patching operaion
	#restrict memory use to make it go faster (less paging!)
	xdelta3 -B 1048576 -d -s rootfs.arm.ext2 rootfs.xdt3 newfs.ext2
	mv -f newfs.ext2 rootfs.arm.ext2

fi
