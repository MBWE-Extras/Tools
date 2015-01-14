#!/bin/sh

CURDIR=$(pwd)
FW_STATUS_FILE=/var/upgrade_download/fwud_status

if [ !  -d /proto/SxM_webui ];then
   echo $(date +"%D %T") "This is not a Mybook WhiteLight Device."
   echo $(date +"%D %T") "this installer is only for  Mybook WhiteLight device , please use the feature pack installer for your device."
   exit 1
fi

if [ ! -f /opt/bin/ipkg ] ;  then
   echo "10%" >$FW_STATUS_FILE
   echo $(date +"%D %T") "Installing OPTWARE..."

   echo $(date +"%D %T") "Installing the OPTWARE feed ..."
   feed=http://ipkg.nslu2-linux.org/feeds/optware/cs05q1armel/cross/unstable
   ipk_name=$(wget -qO- $feed/Packages | awk '/^Filename: ipkg-opt/ {print $2}')
   wget $feed/$ipk_name
   tar -xOvzf $ipk_name ./data.tar.gz | tar -C / -xzvf -
   mkdir -p /opt/etc/ipkg
   echo "src armel http://ipkg.nslu2-linux.org/feeds/optware/cs05q1armel/cross/unstable" > /opt/etc/ipkg/armel-feed.conf
   /opt/bin/ipkg update

   export PATH=$PATH:/opt/bin

   echo "20%" >$FW_STATUS_FILE
   echo $(date +"%D %T") "configuring correct OPTWARE Environment ..."
        [ ! -e  /root/.bashrc ] && echo  "WARNING : /root/.bashrc does not exist"
        [ "`grep -c "/opt/bin" /root/.bashrc`" -eq "0" ] && echo -en "\n export PATH=\$PATH:/opt/bin:/opt/sbin" >>/root/.bashrc

        [ ! -e  /root/.bash_profile ] && echo  "WARNING : /root/.bash_profile does not exist"
        [ "`grep -c "/opt/bin" /root/.bash_profile`" -eq "0" ] && echo -en "\n export PATH=\$PATH:/opt/bin:/opt/sbin" >>/root/.bash_profile

        if [ ! -e  /etc/profile ];then
           touch /etc/profile
        fi
        if [ "`cat /etc/profile|grep -c /opt/bin `" -eq "0" ];then
           echo -en "\n PATH=\$PATH:/opt/bin:/opt/sbin" >>/etc/profile
           echo -en "\n export PATH " >>/etc/profile
        fi
fi

echo "30%" >$FW_STATUS_FILE
if  [ ! -f /etc/init.d/S90optware ] ;  then
    echo $(date +"%D %T") "configuring OPTWARE startup scripts ..."
    echo "if [ -d /opt/etc/init.d ]; then" >/etc/init.d/S99toptware
    echo "   for f in /opt/etc/init.d/S* ; do" >>/etc/init.d/S99toptware
    echo "   [ -x \$f ] && \$f start" >>/etc/init.d/S99toptware
    echo "   done" >>/etc/init.d/S99toptware
    echo "fi" >>/etc/init.d/S99toptware
    chmod +x /etc/init.d/S99toptware
fi

echo "40%" >$FW_STATUS_FILE
if [ ! -e /usr/bin/sort ] ;then
   echo $(date +"%D %T") "installing sort tools ..."
   mv -f sort /usr/bin/sort
   chmod +x /usr/bin/sort
fi

echo "45%" >$FW_STATUS_FILE
if [ ! -e /usr/bin/dirname ] ;then
   echo $(date +"%D %T") "installing dirname tools ..."
   mv -f dirname /usr/bin/dirname
   chmod +x /usr/bin/dirname
fi

echo "50%" >$FW_STATUS_FILE
if [ ! -e /opt/bin/perl ] ;then
   echo $(date +"%D %T") "installing perl..."
   /opt/bin/ipkg update
   /opt/bin/ipkg install perl
fi

echo $(date +"%D %T") "Installing FeaturePack Manager ..."

echo "60%" >$FW_STATUS_FILE
if [ ! -d /proto/SxM_webui/fpkmgr ] ;then
   mkdir /proto/SxM_webui/fpkmgr
fi

echo "65%" >$FW_STATUS_FILE
if [ ! -d /proto/SxM_webui/fpkmgr/fpks ] ;then
   mkdir /proto/SxM_webui/fpkmgr/fpks
fi

echo "70%" >$FW_STATUS_FILE
if [ ! -d /proto/SxM_webui/fpkmgr/temp ] ;then
   mkdir /proto/SxM_webui/fpkmgr/temp
fi

echo "75%" >$FW_STATUS_FILE
mv -f index.php /proto/SxM_webui/fpkmgr/index.php
chmod +x /proto/SxM_webui/fpkmgr/index.php

echo "80%" >$FW_STATUS_FILE
mv -f HTML.tar /proto/SxM_webui/fpkmgr/HTML.tar
cd /proto/SxM_webui/fpkmgr
tar -xf /proto/SxM_webui/fpkmgr/HTML.tar  
rm "/proto/SxM_webui/fpkmgr/HTML.tar"
cd $CURDIR

echo "85%" >$FW_STATUS_FILE
mv -f System_Configuration.tar /proto/SxM_webui/fpkmgr/fpks/System_Configuration.tar
cd /proto/SxM_webui/fpkmgr/fpks
tar -xf /proto/SxM_webui/fpkmgr/fpks/System_Configuration.tar
rm "/proto/SxM_webui/fpkmgr/fpks/System_Configuration.tar"
cd $CURDIR

echo "90%" >$FW_STATUS_FILE
sh /proto/SxM_webui/fpkmgr/fpks/System_Configuration/_install

# Updating the original WD index.php file...
if [ ! -e /proto/SxM_webui/index.php.ori ] ;then
   /opt/bin/perl updatessm.pl
   rm -f updatessm.pl
fi

rm -f "./FeaturePackInstaller.sh"
echo "100%" >$FW_STATUS_FILE
echo $(date +"%D %T") "Installation Complete"
