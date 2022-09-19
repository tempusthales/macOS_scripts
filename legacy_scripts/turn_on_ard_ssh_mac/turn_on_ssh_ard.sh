#!/bin/bash

adminuser=your_admin_account

sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -allowAccessFor -specifiedUsers
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -users $adminuser -privs -all -restart -agent -menu

# Turn on SSH
systemsetup -setremotelogin on
dseditgroup -o create -q com.apple.access_ssh 
dseditgroup -o edit -a admin -t group com.apple.access_ssh 

# Restart SSH service
sudo launchctl unload -w /System/Library/LaunchDaemons/ssh.plist
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist

exit 0
