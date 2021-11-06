#!/bin/bash -x

# extract just the mount name
DEVICE=`lsblk -Pf | grep Passport | cut -d ' ' -f 1 | cut -c 7-10`

umount /media/kaipada/My\ Passport
umount /media/kaipada/My\ passport
umount /media/kaipada/My_passport
sleep 5s
mkdir /media/kaipada/My\ Passport
mkdir /media/kaipada/My\ passport
mkdir /media/kaipada/My_passport

mount /dev/$DEVICE /media/kaipada/My_passport

if [ $? -eq 0 ]; then
   echo "Device mounted"
else
   echo "Device FAIL to mount !!!"
   exit 1
fi

rsync -azvv --progress /home/kaipada/media/movies/* /media/kaipada/My_passport/movies
sleep 5s
rsync -azvv --progress /home/kaipada/media/tv/* /media/kaipada/My_passport/tv
sleep 5s
umount /media/kaipada/My\ Passport
umount /media/kaipada/My\ passport
umount /media/kaipada/My_passport
sleep 5s
rmdir /media/kaipada/My\ Passport
rmdir /media/kaipada/My\ passport
rmdir /media/kaipada/My_passport

# unmount everything at the end so the drive sleeps for rest of the day
