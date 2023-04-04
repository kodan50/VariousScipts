#!/bin/bash

# We want to make sure this runs as a root user.

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

 # We are going to expand on this in due time. Right now, this works with devices that speak ATA.
 # This can probably wipe your OS drive, so you should not use this for any reason. And if you do, I am not responsible for nuking your computer.
 
sudo hwinfo --disk --short
echo "Which drive do you want to wipe and erase?"
echo "Please type the entire path to the device"
read DriveToWipe
echo Wiping $DriveToWipe...
sudo hdparm -I $DriveToWipe | grep frozen
sudo hdparm --user-master u --security-set-pass Eins $DriveToWipe
sudo hdparm --user-master u --security-erase Eins $DriveToWipe
