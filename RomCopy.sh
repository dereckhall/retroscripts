#!/bin/bash

# 2018.08.31
# small script to automate/simplify copying roms from an inserted usb drive to internal storage within emulationstation/retropie
# place RomCopy.sh in /home/pi/RetroPie/retropiemenu/ and set permissions - chmod +x RomCopy.sh
# restart emulationstation and you now see it as an option when opening the retropie menu
# it expects the usb drive to have the following folder/file layout
# usbdrive: roms-folder:-> nes,snes,megadrive,etc with rom files contained within those directories.
# format usb as fat32, and create your layout like i mentioned above, insert usb drive, and navigate/click on RomCopy.
# i hope this helps someone.
# by outz/dereck

# 2018.09.01
# added the ability to backup current roms, scraped coverart, gamelist data to USB, as well as the ability to
# restore those backups all from the RomCopy menu system. This should alleviate some of the pain when installing new
# RetrOrange releases.

mountfunc() {
	/usr/bin/sudo /bin/umount /media > /dev/null 2>&1

	MOUNT=$(/usr/bin/sudo /bin/mount /dev/sda1 /media -o uid=pi,gid=pi> /dev/null 2>&1)
	MOUNTEC=$?

	if [ $MOUNTEC -eq 0 ]; then
		dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Successfully mounted the USB drive \n\n...Please wait" 5 40
		sleep 4
	else
		dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Unable to mount USB drive \n\n...Exiting" 5 40
		sleep 4
		exit 1
	fi
}

umountfunc() {
	UMOUNT=$(/usr/bin/sudo /bin/umount /media > /dev/null 2>&1)
	UMOUNTEC=$?

	if [ $UMOUNTEC -eq 0 ]; then
    	exit 0
	else
    	dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Unable to unmount USB drive \n\n...Exiting" 5 40
    	sleep 4
	fi
}

rcbkup="/media/rcbackup"

rcmcmd=(dialog --keep-tite --no-shadow --cr-wrap --keep-window --menu "RomCopy Menu System (Insert USB Drive Now)" 22 101 16)

rcmoptions=(
1 "Copy roms from USB to internal"
2 "Backup current roms, data to USB"
3 "Restore previous backup from USB"
4 "Exit"
)

rcmchoices=$("${rcmcmd[@]}" "${rcmoptions[@]}" 2>&1 >/dev/tty)

for rcmchoice in $rcmchoices
do
    case $rcmchoice in
        1)
			mountfunc
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
				done
			)

			/bin/chown -R pi.pi $DST
			dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Copy complete.\n\n...Please wait" 5 40
			umountfunc
            ;;
        2)
			mountfunc
			/bin/mkdir "$rcbkup" > /dev/null 2>&1
			dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Backing up data to USB\n\n...Please wait" 10 80
			echo "0" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup in progress \n\n/home/pi/RetroPie/roms\n\n...Please wait" 10 80 0
			cd /home/pi/RetroPie/
			/bin/tar cfz "$rcbkup"/roms.tar.gz ./roms
			echo "33" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup in progress \n\n/opt/retropie/configs/all/emulationstation/downloaded)images\n\n...Please wait" 10 80 0
			cd /opt/retropie/configs/all/emulationstation/
			/bin/tar cfz "$rcbkup"/downloaded_images.tar.gz ./downloaded_images
			echo "66" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup in progress \n\n/opt/retropie/configs/all/emulationstation/gamelists\n\n...Please wait" 10 80 0
			cd /opt/retropie/configs/all/emulationstation/
			/bin/tar cfz "$rcbkup"/gamelists.tar.gz --exclude='retropie' ./gamelists
            echo "100" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup to USB complete" 10 80 0
			umountfunc
            ;;
        3)
            echo "Third Option"
			mountfunc
			(pv -n "$rcbkup"/roms.tar.gz | tar xzf - -C /home/pi/RetroPie/ ) 2>&1 | dialog --gauge "Restore in progress \n\n/home/pi/RetroPie/roms\n\n...Please wait" 10 80 0
            (pv -n "$rcbkup"/downloaded_images.tar.gz | tar xzf - -C /opt/retropie/configs/all/emulationstation/ ) 2>&1 | dialog --gauge "Restore in progress \n\n/opt/retropie/configs/all/emulationstation/downloaded)images\n\n...Please wait" 10 80 0
            (pv -n "$rcbkup"/gamelists.tar.gz | tar xzf - -C /opt/retropie/configs/all/emulationstation/ ) 2>&1 | dialog --gauge "Restore in progress \n\n/opt/retropie/configs/all/emulationstation/gamelists\n\n...Please wait" 10 80 0
			umountfunc
            ;;
        4)
            echo "...Exiting"
			exit 0
            ;;
    esac
done
