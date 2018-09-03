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
# added the ability to backup current roms, scraped coverart, gamelist data, wifi settings to USB, as well as the ability to
# restore those backups all from the RomCopy menu system. This should alleviate some of the pain when installing new
# RetrOrange releases.

mainfunc() {
	menufunc
}

mountfunc() {
	/usr/bin/sudo /bin/umount /media > /dev/null 2>&1

	MOUNT=$(/usr/bin/sudo /bin/mount /dev/sda1 /media -o uid=pi,gid=pi> /dev/null 2>&1)
	MOUNTEC=$?

	if [ $MOUNTEC -eq 0 ]; then
		dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Successfully mounted the USB drive \n\n...Please wait" 5 40
		sleep 4
		return
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
		dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Successfully unmounted the USB drive \n\n...Please wait" 5 40
		sleep 4
		return
	else
		dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Unable to unmount USB drive \n\n...Exiting" 5 40
		sleep 4
		exit 1
	fi
}

menufunc() {
	rcbkup="/media/rcbackup"
	rcmcmd=(dialog --keep-tite --no-shadow --cr-wrap --keep-window --menu "RomCopy Menu System (Insert USB Drive Now)" 22 101 16)

	rcmoptions=(
	1 "Copy new roms USB to internal"
	2 "Backup current roms to USB"
	3 "Restore rom backup from USB"
	4 "Backup WiFi settings to USB"
	5 "Restore WiFi backup from USB"
	254 "Reboot"
	255 "Exit"
	)

	rcmchoices=$("${rcmcmd[@]}" "${rcmoptions[@]}" 2>&1 >/dev/tty)

for rcmchoice in $rcmchoices
do
	case $rcmchoice in
		1)
			mountfunc
			/bin/mkdir /media/roms
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
			umountfunc
			dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Rom copy complete.\n\n...Please wait" 5 40
			sleep 4
			mainfunc
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
			/bin/tar cfz "$rcbkup"/gamelists.tar.gz ./gamelists
			if [ -f "$rcbkup"/roms.tar.gz ] && [ -f "$rcbkup"/downloaded_images.tar.gz ] && [ -f "$rcbkup"/gamelists.tar.gz ]; then
				umountfunc
	            		echo "100" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup roms to USB complete" 10 80 0
				sleep 4
				mainfunc
			else
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "ERROR: Backup roms to USB failed" 10 80 0
				sleep 4
				mainfunc
			fi
			;;
		3)
			mountfunc
			if [ -f "$rcbkup"/roms.tar.gz ] && [ -f "$rcbkup"/downloaded_images.tar.gz ] && [ -f "$rcbkup"/gamelists.tar.gz ]; then
				rm -fr /home/pi/RetroPie/roms/*
				(pv -n "$rcbkup"/roms.tar.gz | tar xzf - -C /home/pi/RetroPie/ ) 2>&1 | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Restore in progress \n\n/home/pi/RetroPie/roms\n\n...Please wait" 10 80 0
				(pv -n "$rcbkup"/downloaded_images.tar.gz | tar xzf - -C /opt/retropie/configs/all/emulationstation/ ) 2>&1 | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Restore in progress \n\n/opt/retropie/configs/all/emulationstation/downloaded)images\n\n...Please wait" 10 80 0
				(pv -n "$rcbkup"/gamelists.tar.gz | tar xzf - -C /opt/retropie/configs/all/emulationstation/ ) 2>&1 | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Restore in progress \n\n/opt/retropie/configs/all/emulationstation/gamelists\n\n...Please wait" 10 80 0
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Restore of rom data successful\n\nReboot to complete\n\n...Exiting" 10 80
				sleep 4
				mainfunc
			else
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "ERROR: Backup rom data does not exist on USB drive\n\n...Exiting" 10 80
				sleep 4
				mainfunc
			fi
			;;
		4)
			mountfunc
			/bin/mkdir "$rcbkup" > /dev/null 2>&1
			dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Backing up WiFi settings to USB\n\n...Please wait" 10 80
			echo "0" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup in progress \n\n/etc/NetworkManager\n\n...Please wait" 10 80 0
			cd /etc/
			/usr/bin/sudo /bin/tar cfz "$rcbkup"/networkmanager.tar.gz ./NetworkManager
			if [ -f "$rcbkup"/networkmanager.tar.gz ]; then
				umountfunc
				echo "100" | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Backup of WiFi to USB complete" 10 80 0
				sleep 4
				mainfunc
			else
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "ERROR: Backup WiFi data to USB failed" 10 80
				sleep 4
				mainfunc
			fi
			;;
		5)
			mountfunc
			if [ -f "$rcbkup"/networkmanager.tar.gz ]; then
				(pv -n "$rcbkup"/networkmanager.tar.gz | /usr/bin/sudo tar xzf - -C /etc/ ) 2>&1 | dialog --keep-tite --no-shadow --cr-wrap --keep-window --gauge "Restore in progress \n\n/etc/NetworkManager\n\n...Please wait" 10 80 0
				/usr/bin/sudo /bin/cp /etc/rc.local /etc/rc.local.orig
				/usr/bin/sudo sed -i '/exit 0/d' /etc/rc.local > /dev/null 2>&1
				/usr/bin/sudo sed -i '/ifdown eth0/d' /etc/rc.local > /dev/null 2>&1
				echo "ifdown eth0" | /usr/bin/sudo /usr/bin/tee -a /etc/rc.local > /dev/null
				echo "exit 0" | /usr/bin/sudo /usr/bin/tee -a /etc/rc.local > /dev/null
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "Restore of WiFi data successful\n\nReboot to complete\n\n...Exiting" 10 80
				sleep 4
				mainfunc
			else
				umountfunc
				dialog --keep-tite --no-shadow --cr-wrap --keep-window --infobox "ERROR: Backup WiFi data does not exist on USB drive\n\n...Exiting" 10 80
				sleep 4
				mainfunc
			fi
			;;
		254)
			echo "...Rebooting"
			/usr/bin/sudo /bin/reboot
			;;
		255)
			echo "...Exiting"
			exit 0
			;;
	esac
done

}

mainfunc
