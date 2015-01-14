#!/bin/sh
# This script is used to reserve files in the reserve_list
# before firmware upgrade
# 
FILE=/var/upgrade/reserve.list
backup=/var/lib/backup
log_file=/var/lib/upgrade_log
files=0
echo "reserve.sh $(date) running" >> $log_file

if [ ! -e $FILE ]
then
echo "fail 10: $FILE doesn't exist!!" >> $log_file
exit 10
fi

if [ -e $backup/reserved ]
then
echo "Delet all old reserved files" >> $log_file
rm -f $backup/*
fi

echo "$FILE exist!!"
exec < $FILE
while read line
do 
   files=$(($files+1))
   echo "$files $line" >> $log_file
   if [ ! -e $line ]
   then
   echo "fail 20: $line doesn't exist!!" >> $log_file
#   exit 20
#   fi
   else
   if [ -d $backup ] || mkdir $backup
   then
#   echo "$line exist!! copy file" >> $log_file
   /bin/tar -rpPvf $backup/reserve.tar $line >> $backup/tar_log
   fi
   fi
done

if [ $files -eq 0 ]
then
  echo "fail 30: No file list in reserve_list!!" >> $log_file
  exit 30
fi
    

if [ ! -e $backup/reserve.tar ]
then
  echo "fail 40: Reserve files fail!!" >> $log_file
  exit 40
fi

touch $backup/reserved
echo "\n$(date)" > $backup/reserved
echo "$files files have been reserved" >> $backup/reserved
exit 0
