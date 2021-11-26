#!/bin/bash

function mount_passport() {

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

}
export -f mount_passport
