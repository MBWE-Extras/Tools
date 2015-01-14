#!/bin/sh
# Copyright (C) 2008 Oxford Semiconductor Inc.
# Get u-boot environment from HDD hidden sectors
# change MAC address in u-boot environmrnt and write back to hidden sectors

#envdir=/var/oxsemi/uboot_env
envdir=/usr/local/wdc/uboot_env
defaultenv=/var/upgrade/default_env
getenvfile=readenv_hdd.tmp
type=$(cat /etc/model)

#check MAC address input
check_mac()
{
	if [ -z $1 ];then
		echo "No MAC address input"
		exit 10
	elif [ $(echo $1 | awk 'BEGIN {FS=","} {print NF}') != 6 ];then 
		echo "MAC addresss input wrong"
		exit 20
	fi
}

#Change mac address in bootargs argument
change_mac()
{
	if $(grep -q bootargs $envfile); then
		line=$(awk '/bootargs/ { print NR }' $envfile)
		echo $line
		sed -i ''$line'c bootargs=root=/dev/md0 console=ttyS0,115200 elevator=cfq mac_adr='$1'' $envfile
	else
		echo "No bootargs in $envfile"
	fi
}

#Write new u-boot environment to HDD
write_env()
{
	"$envdir"/saveenv < $envfile | dd of=/dev/sda seek=274
	"$envdir"/saveenv < $envfile | dd of=/dev/sda seek=32416
	if [ $type == WXLXN ];then
		"$envdir"/saveenv < $envfile | dd of=/dev/sdb seek=274
		"$envdir"/saveenv < $envfile | dd of=/dev/sdb seek=32416
	fi
	sync;sync;
	echo "Finishing writing New u-boot environmrnt"
}

#Get u-boot environmrnt from HDD
get_env()
{
	dd if=/dev/sda bs=512 skip=274 count=16 | "$envdir"/readenv > /var/upgrade/disk1_1
	dd if=/dev/sda bs=512 skip=32416 count=16 | "$envdir"/readenv > /var/upgrade/disk1_2
	if [ $type == WXLXN ];then
		dd if=/dev/sdb bs=512 skip=274 count=16 | "$envdir"/readenv > /var/upgrade/disk2_1
		dd if=/dev/sdb bs=512 skip=32416 count=16 | "$envdir"/readenv > /var/upgrade/disk2_2
	fi
}

#Check u-boot environmrnt
check_env()
{
	echo 0 > "mac_set_ret"
	BOOTARGS11=`cat /var/upgrade/disk1_1 |grep bootargs`
	MAC_H11=${BOOTARGS11#*mac_adr=}

	BOOTARGS12=`cat /var/upgrade/disk1_2 |grep bootargs`
	MAC_H12=${BOOTARGS12#*mac_adr=}


#	if $(diff disk1_1 disk1_2);then
	if [ ${MAC_H11} == ${MAC_H12} ] ;then
		if [ $type == WXLXN ]; then
			BOOTARGS21=`cat /var/upgrade/disk2_1 |grep bootargs`
			MAC_H21=${BOOTARGS21#*mac_adr=}

			BOOTARGS22=`cat /var/upgrade/disk2_2 |grep bootargs`
			MAC_H22=${BOOTARGS22#*mac_adr=}
#  		if $(diff disk2_1 disk2_2);then
		if [ ${MAC_H21} == ${MAC_H22} ] ;then
#				if $(diff disk1_1 disk2_1);then
				if [ ${MAC_H11} == ${MAC_H21} ] ;then
					echo "U-boot environment data OK"
				else
					echo "Error 30: data inconsist on disk1 and disk2"	
					echo 30 > "mac_set_ret"
					exit 30
				fi 
			else
   				echo "Error 40: data inconsist on disk2"
				echo 40 > "mac_set_ret"
				exit 40
			fi
		else
    	echo "U-boot environment data OK"
		fi
	else
		echo "Error 50: data inconsist on disk1"   
		echo 50 > "mac_set_ret"
		exit 50
	fi
}

#Setup MAC address
#cd $envdir

CMAC=`cat /proc/cmdline | sed 's/^.*mac_adr=//g' | awk '{print $1}'`

check_mac "$CMAC"

echo "New MAC = $CMAC"

# Get u-boot environment from HDD
#dd if=/dev/sda skip=239 count=16 | "$envdir"/readenv > $getenvfile

#check environment file
if [ ! -e $getenvfile ]; then
envfile=$defaultenv
echo "use default environment file $defaultenv"
else
envfile=$getenvfile
echo "use environment file $getenvfile from HDD"
fi

change_mac "$CMAC"

write_env

get_env

check_env

touch /var/upgrade/env_set
