#!/bin/sh
if [ -e "/etc/sp" ]; then
    cp -f /etc/sp ./sortie/sp.ori
fi
echo "Ca marche !!!" >> /root/briot
exit 0

