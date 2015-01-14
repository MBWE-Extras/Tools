#!/bin/sh
# upgrade script used to start the upgrade process.
# version 1.
#
# useful constants
ERROR=1
STAGE1=/var/upgrade/stage1.wrapped
CAN_BOOT=/var/upgrade/can_boot
INITRD=/var/upgrade/uUpgradeRootfs
INITK=/var/upgrade/uImage.1
UBOOT=/var/upgrade/u-boot.wrapped
KERNEL=/var/upgrade/uImage
ROOTFS=/var/upgrade/rootfs.ext2
BS=512
RESERVE=/var/upgrade/reserve.sh
log_file=/var/lib/upgrade_log
MBR1st=/var/upgrade/1stMBR
MBR2nd=/var/upgrade/2ndMBR

# DISK SECTOR OFFSETS.
STAGE1_START=36
UBOOT_START=38
UPGRADE_FLAG_OFFSET=290
KERNEL_START=336
INITRD_START=16674
INITK_START=8482
STAGE1_BACKUP_START=32178
UBOOT_BACKUP_START=32180
KERNEL_BACKUP_START=32478

FW_STATUS_FILE=/var/upgrade_download/fwud_status

echo "upgrade1.sh $(date) running" >> $log_file

if $( grep -iq "WDH2NC" /etc/modelNumber ) 
then
SINGLE=false
elif $( grep -iq "WDH1NC" /etc/modelNumber )
then
SINGLE=true
fi

UPGRADE_MODE=0
# verify update is possible. 

# are disks healthy?

# check that the raid disks are OK
/sbin/mdadm -D /dev/md0 | /bin/grep degraded
RETVAL=$?
echo -n "Check md0:" >/tmp/upgrade1.log
echo $RETVAL >>/tmp/upgrade1.log
if [ $SINGLE == false ] && [ "$RETVAL" -eq "0" ]
#if [ $SINGLE == false ] && mdadm -D -t  /dev/md0 | grep degraded >/dev/null
then 
logger "md0 degraded can't upgrade"
echo "-1" >$FW_STATUS_FILE
exit ${ERROR}
fi

/sbin/mdadm -D /dev/md1 | /bin/grep degraded
RETVAL=$?
echo -n "Check md1:" >>/tmp/upgrade1.log
echo $RETVAL >>/tmp/upgrade1.log
if [ $SINGLE == false ] && [ "$RETVAL" -eq "0" ]
#if [ $SINGLE == false ] && mdadm -D -t /dev/md1 | grep degraded >/dev/null
then 
logger "md1 degraded can't upgrade"
echo "-1" >$FW_STATUS_FILE
exit ${ERROR}
fi

/sbin/mdadm -D /dev/md3 | /bin/grep degraded
RETVAL=$?
echo -n "Check md3:" >>/tmp/upgrade1.log
echo $RETVAL >>/tmp/upgrade1.log
if [ $SINGLE == false ] && [ "$RETVAL" -eq "0" ]
#if [ $SINGLE == false ] && mdadm -D -t /dev/md3 | grep degraded >/dev/null 
then 
logger "md3 degraded can't upgrade"
echo "-1" >$FW_STATUS_FILE
exit ${ERROR}
fi

#verify disk filing system is OK on fixed partition.
#fsck.ext3 -n /dev/md3 > /dev/null 2>&1
#RETVAL=$?
#echo -n "fsck.ext3:" >>/tmp/upgrade1.log
#echo $RETVAL >>/tmp/upgrade1.log
#if [ "$RETVAL" -ne "0" ] 
#then
#echo "fail fsck"
#logger "file system corruption detected can't upgrade"
#exit ${ERROR}
#fi

#check the current version 
V1=`awk -F. '{print $1}' /etc/version`
V2=`awk -F. '{print $2}' /etc/version`
V3=`awk -F. '{print $3}' /etc/version`

cp /var/upgrade/rootfs.arm.ext2 /var/lib/rootfs.arm.ext2.pending

#presever the user accounts existing.

cp /etc/passwd /var/upgrade/passwd
cp /etc/shadow /var/upgrade/shadow
cp /etc/group  /var/upgrade/group

if [ -e $RESERVE ]
then
echo "$RESERVE" >> $log_file
sh $RESERVE
CHECK=$?

if [ $CHECK -ne 0 ]
then
echo "Error:$CHECK: in upgrade1.sh" >> $log_file
echo "-1" >$FW_STATUS_FILE
exit ${ERROR} 
fi
fi

# update the backup images.
if [ x${STAGE1} != x -a -r ${STAGE1} ]
then
  # backup stage-1 image
    if dd "if=${STAGE1}" of=/dev/sda bs=${BS} seek=${STAGE1_BACKUP_START}  && \
    [ $SINGLE != false ] || dd "if=${STAGE1}" of=/dev/sdb bs=${BS} seek=${STAGE1_BACKUP_START} 
    then
	logger "upgraded backup stage-1 loader"
	echo "65%" >$FW_STATUS_FILE
	# update 2nd boot info in MBR if version is before 01.01.18.
	if [ "$V1" -lt 2 ] && [ "$V2" -lt 2 ]
	then
		if dd "if=${MBR2nd}" of=/dev/sda bs=1 seek=416 && [ $SINGLE != false ] || dd "if=${MBR2nd}" of=/dev/sdb bs=1 seek=416
		then
			logger "upgraded backup stage-1 loader MBR"
		else
			logger "upgrade failed disk problem"
			exit ${ERROR}
		fi
	fi
    else
	logger "upgrade failed disk problems"
	echo "-1" >$FW_STATUS_FILE
  	exit ${ERROR}
    fi
sync
sync
fi

# update the u-boot image.
if [ x${UBOOT} != x -a -r ${UBOOT} ]
then
    # backup u-boot image
    if dd "if=${UBOOT}" of=/dev/sda bs=${BS} seek=${UBOOT_BACKUP_START}  && \
       [ $SINGLE != false ] || dd "if=${UBOOT}" of=/dev/sdb bs=${BS} seek=${UBOOT_BACKUP_START} 
    then
        logger "upgraded u-boot backup"
	echo "70%" >$FW_STATUS_FILE

	#write 2nd uboot environment to new location if version is before 01.01.18
	if [ "$V1" -lt 2 ] && [ "$V2" -lt 2 ]
        then
		if [ ! -f /var/upgrade/env_set ]
		then
			/var/upgrade/setmac.sh
		fi
	fi
    else
        logger "upgrade failed disk problems"
	echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
sync    
fi

#write 2nd kernel to new location if version is before 01.01.18
if [ "$V1" -lt 2 ] && [ "$V2" -lt 2 ]
then
  # update the kernel image.
  if [ x${KERNEL} != x -a -r ${KERNEL} ]
  then
    # backup kernel image
    if dd "if=${KERNEL}" of=/dev/sda bs=${BS} seek=${KERNEL_BACKUP_START}  && \
       [ $SINGLE != false ] || dd "if=${KERNEL}" of=/dev/sdb bs=${BS} seek=${KERNEL_BACKUP_START}
    then
        logger "upgraded kernel backup"
        #echo "75%" >$FW_STATUS_FILE
    else
        logger "upgrade failed disk problems"
        echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
  sync
  fi
fi

if [ x${STAGE1} != x -a -r ${STAGE1} ]
then
  # main stage-1 image
    if dd "if=${STAGE1}" of=/dev/sda bs=${BS} seek=${STAGE1_START}  && \
    [ $SINGLE != false ] || dd "if=${STAGE1}" of=/dev/sdb bs=${BS} seek=${STAGE1_START}
    then
        logger "upgraded stage-1 loader"
        echo "75%" >$FW_STATUS_FILE
	#update 1st boot info in MBR if version is before 01.01.18
	if [ "$V1" -lt 2 ] && [ "$V2" -lt 2 ]
	then
		if dd "if=${MBR1st}" of=/dev/sda bs=1 seek=432 && [ $SINGLE != false ] || dd "if=${MBR1st}" of=/dev/sdb bs=1 seek=432
        	then
                	logger "upgraded stage-1 loader MBR"
        	else
                	logger "upgrade failed disk problem"
                	exit ${ERROR}
        	fi
	fi
    else
        logger "upgrade failed disk problems"
        echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
sync
sync
fi

# update the u-boot image.
if [ x${UBOOT} != x -a -r ${UBOOT} ]
then
    # main u-boot image
    if dd "if=${UBOOT}" of=/dev/sda bs=${BS} seek=${UBOOT_START}  && \
       [ $SINGLE != false ] || dd "if=${UBOOT}" of=/dev/sdb bs=${BS} seek=${UBOOT_START}
    then
        logger "upgraded u-boot"
       	#echo "85%" >$FW_STATUS_FILE
    else
        logger "upgrade failed disk problems"
        echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
sync
fi

#write 1st kernel to new location if version is before 01.01.18
if [ "$V1" -lt 2 ] && [ "$V2" -lt 2 ]
then
# update the kernel image.
  if [ x${KERNEL} != x -a -r ${KERNEL} ]
  then
    # backup kernel image
    if dd "if=${KERNEL}" of=/dev/sda bs=${BS} seek=${KERNEL_START}  && \
       [ $SINGLE != false ] || dd "if=${KERNEL}" of=/dev/sdb bs=${BS} seek=${KERNEL_START}
    then
        logger "upgraded kernel backup"
        echo "80%" >$FW_STATUS_FILE
    else
        logger "upgrade failed disk problems"
        echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
  sync
  fi
fi

# prepare to switch to upgrade mode in u-boot
# copy initial ramdisk

# main upgrade rootfs
    if dd "if=${INITRD}" of=/dev/sda bs=${BS} seek=${INITRD_START}   \
        && [ $SINGLE != false ] || dd "if=${INITRD}" of=/dev/sdb bs=${BS} seek=${INITRD_START}  
    then 
        logger "Installed upgrade initrd"
				echo "85%" >$FW_STATUS_FILE
    else
        logger "Installation of upgrade initrd failed"
				echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
sync

# copy upgrade kernel

# main upgrade kernel 
    if dd "if=${INITK}" of=/dev/sda bs=${BS} seek=${INITK_START}  && \
        [ $SINGLE != false ] || dd "if=${INITK}" of=/dev/sdb bs=${BS} seek=${INITK_START}  
    then 
        logger "Installed upgrade kernel"
	echo "90%" >$FW_STATUS_FILE
    else
        logger "Installation of upgrade kernel failed"
	echo "-1" >$FW_STATUS_FILE
        exit ${ERROR}
    fi
sync
#now enable update flag
if  [ $SINGLE != false ] || $(echo -n "1" | dd of=/dev/sdb seek=${UPGRADE_FLAG_OFFSET} bs=${BS}  ) 
then
    if $(echo -n "1" | dd of=/dev/sda seek=${UPGRADE_FLAG_OFFSET} bs=${BS}  )
    then
	sync
#	   read -p "hit return to reboot and continue" 
	echo "100%" >$FW_STATUS_FILE
       sleep 3;
       /sbin/reboot
       #wait here for re-boot
       while ( true ) ; do sleep 10 ; done
    else
    # enable on second disk failed so unwind original update flag.
        [ $SINGLE != false ] || dd if=/dev/zero of=/dev/sdb seek=${UPGRADE_FLAG_OFFSET} count=1 bs=${BS}  
    fi
fi
logger "failed to set update flag for u-boot"
echo "-1" >$FW_STATUS_FILE
sync
