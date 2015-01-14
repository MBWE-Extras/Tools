#!/bin/sh

LIB=/var/lib
backup=$LIB/backup
echo "upgrad2.sh $(date) running" >> /var/lib/upgrade_log
update_passwds() {
	# update group file - merge existing and copied group file 
	awk -F ':' '$3 <= 90 {print}' /etc/group > /etc/group.tmp
	awk -F ':' '$3 >  90 {print}' /var/upgrade/group >> /etc/group.tmp
	mv -f /etc/group.tmp /etc/group

	# update passwd file 
	awk -F ':' '$3 <= 90 {print}' /etc/passwd > /etc/passwd.tmp
	awk -F ':' '$3 >  90 {print}' /var/upgrade/passwd >> /etc/passwd.tmp
	mv -f /etc/passwd.tmp /etc/passwd

	# update shadow file
	for x in $(awk -F ':' '$3 <= 90 {print $1}' /etc/passwd  )
	do
		grep "^$x:" /etc/shadow >> /etc/shadow.tmp
	done
	
	for x in $(awk -F ':' '$3 > 90 {print $1}' /etc/passwd )
	do
		grep "^$x:" /var/upgrade/shadow >> /etc/shadow.tmp
	done

	mv -f /etc/shadow.tmp /etc/shadow
	chmod 0600 /etc/shadow

}

save_upgrade() {
	(cd /var/upgrade ; cp stage1.wrapped u-boot.wrapped uImage uImage.1  uUpgradeRootfs md5sum.lst ${LIB} )
    mv -f /var/lib/rootfs.arm.ext2.pending  /var/lib/rootfs.arm.ext2
	
}

# This script finishes the upgrade process by removing the various parts downloaded for the upgrade.
lock_file="/tmp/active_upgrade"

# lock file deleted by re-writting root file system.
if [ ! -e ${lock_file} ]
then
	update_passwds
	save_upgrade
	if [ -e $backup/reserved ]
	then
	echo "copy reserved files back" >> /var/lib/upgrade_log
	/bin/tar -xvpPf $backup/reserve.tar >> $backup/tar_log
	fi

#restore software configuration
        cd /var/upgrade
	ISSUE=$(grep ROOTFSVERSION /var/upgrade/packing.lst)
        version=$( expr  "$ISSUE" :  '.*=\(.*\)' )
        echo "${version}:$(date):upgrade complete" >> /var/log/upgrades
	echo "${version}" > /var/lib/current-version
	touch /var/upgrade/fwinstalled
        if [ -f /var/lib/rootfs.arm.ext2.pending ] ; then rm -f /var/lib/rootfs.arm.ext2.pending ; fi
        if [ -f /var/lib/backup/reserve.tar ] ; then rm -f /var/lib/backup/reserve.tar ; fi
        if [ -f /var/lib/backup/reserved ] ; then rm -f /var/lib/backup/reserved ; fi
        if [ -d /var/upgrade_download ] ; then rm -rf /var/upgrade_download ; fi
fi
# remove remains of upgrade (even if it failed).
for i in /var/upgrade/*
do

    if expr "${i}" : ".*fwinstalled" ; then continue; fi

    if [ -f ${i} ] ; then rm -f ${i} ; fi
done

# write fw update time flag
date "+%a, %d %b %Y %T" >/etc/version.update
touch /etc/.FWUpdateTime

