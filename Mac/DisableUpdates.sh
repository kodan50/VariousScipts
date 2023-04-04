#!/bin/bash

# This was ran on Mojave, and an earlier version of Mojave to boot.
# I think this stopped working, so while we can hope, it likely doesn't work anymore.
# I am leaving this here as a reminder to me how much of a catastrophic failure Apple is, and how I have no power to fix their imbecilic decisions.

sudo softwareupdate --ignore "macOS Catalina"
sudo softwareupdate --ignore "MacOS Catalina"
sudo softwareupdate --ignore "macOS Big Sur"
sudo softwareupdate --ignore "MacOS Big Sur"
sudo softwareupdate --ignore "macOS Monterey"
sudo softwareupdate --ignore "MacOS Monterey"
sudo softwareupdate --ignore "macOS Ventura"
sudo softwareupdate --ignore "MacOS Ventura"
sudo defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
sudo killall Dock

sudo mv /System/Library/LaunchAgents/com.apple.SoftwareUpdateNotificationManager.plist /System/Library/LaunchAgentsIgnored
