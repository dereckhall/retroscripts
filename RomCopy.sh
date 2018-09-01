#!/bin/bash

# small script to automate/simplify copying roms from an inserted usb drive to internal storage within emulationstation/retropie
# place RomCopy.sh in /home/pi/RetroPie/retropiemenu/ and set permissions - chmod +x RomCopy.sh
# restart emulationstation and you now see it as an option when opening the retropie menu
#
# it expects the usb drive to have the following folder/file layout
# usbdrive: roms-folder:-> nes,snes,megadrive,etc with rom files contained within those directories.
# format usb as fat32, and create your layout like i mentioned above, insert usb drive, and navigate/click on RomCopy.
# i hope this helps someone.
# by outz/dereck
# 2018.08.31

dialog --keep-tite --no-shadow --cr-wrap --keep-window --title "RomCopy" --clear --yesno "Copy Roms from USB to internal storage?" 5 45
RESPONSE=$?

case $RESPONSE in
  0)
    dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Attempting to mount USB drive \n\n...Please wait" 5 40
    sleep 4
    /usr/bin/sudo /bin/umount /media > /dev/null 2>&1

    MOUNT=$(/usr/bin/sudo /bin/mount /dev/sda1 /media > /dev/null 2>&1)
    MOUNTEC=$?

    if [ $MOUNTEC -eq 0 ]; then
        dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Successfully mounted the USB drive \n\n...Copying files" 5 40
        sleep 4
    else
        dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Unable to mount USB drive \n\n...Exiting" 5 40
        sleep 4
        exit 1
    fi
    ;;

  1)
    echo "No pressed"
    exit 0
    ;;

  255)
    echo "ESC pressed"
    exit 0
    ;;
esac

ARRSRC=(/media/roms/*/*)
DST="/home/pi/RetroPie/roms/"

dialog --keep-tite --no-shadow --cr-wrap --title "Copy files" --gauge "Copying files..." 15 80 < <(
    n=${#ARRSRC[*]};
    i=0
    for fsrc in "${ARRSRC[@]}"
    do
        fdst=$(echo $fsrc | sed s+media+home/pi/RetroPie+)
        PCT=$(( 100*(++i)/n ))
cat <<EOF
XXX
$PCT
Copying file \
\n\nSRC: "$fsrc" \
\n\nDST: "$fdst"
XXX
EOF
        /bin/cp "$fsrc" "$fdst" &>/dev/null
        sleep 4
    done
)

/bin/chown -R pi.pi $DST
dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Copy complete. Unmounting the USB drive \n\n...Please wait" 5 40
sleep 4

UMOUNT=$(/usr/bin/sudo /bin/umount /media > /dev/null 2>&1)
UMOUNTEC=$?

if [ $UMOUNTEC -eq 0 ]; then
    exit 0
else
    dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Unable to unmount USB drive \n\n...Exiting" 5 40
    sleep 4
fi

