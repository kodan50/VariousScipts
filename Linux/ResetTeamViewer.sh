#!/bin/bash

# Probably doesn't work anymore. You might also have to install some stuff to make it work.
# This was in use on Linux Mint a long time ago. Might need some TLC. Or TeamViewer can just stop breaking things.
# It seems to suggest Team Viewer is free for home users, and is still on their website.
# Do not use this for business purposes, or suffer the consequences!

sudo pkill TeamViewer && sleep 10
sudo apt-get purge teamviewer* -y && sleep 10
rm -rf ~/.config/teamviewer && sleep 10
sudo nmcli con down id "Wired connection 1" && sleep 10
sudo ifconfig enp0s25 down && sleep 10
sudo macchanger -r enp0s25 && sleep 10
sudo ifconfig enp0s25 up && sleep 10
sudo nmcli con up id "Wired connection 1" && sleep 10
sudo dpkg -i ~/Downloads/teamviewer_13.1.8286_amd64.deb && sleep 10
sudo apt-get install -f -y && sleep 10
