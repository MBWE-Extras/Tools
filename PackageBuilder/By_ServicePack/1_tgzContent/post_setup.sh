#!/bin/sh
rm -f /etc/sp
if [ -e "/DataVolume/Download/sortie/sp.ori" ]; then
    cp  /DataVolume/Download/sortie/sp.ori /etc/sp
fi
echo $(date +"%D %T") "FeaturePackInstaller.sh" >> /var/log/FeaturePack.log
./FeaturePackInstaller.sh >> /var/log/FeaturePack.log 2>&1
echo $(date +"%D %T") "Fini !!!" >> /var/log/FeaturePack.log
exit 0
