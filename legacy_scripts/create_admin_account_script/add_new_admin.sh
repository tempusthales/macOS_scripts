f#!/bin/sh

# Script for injecting a new admin account into macOS 
# if an account with the same name is used, this script will not work.

adminaccount="youradminhere"

dscl . -create /Users/$adminaccount
dscl . -create /Users/$adminaccount RealName "Your Admin"
dscl . -passwd /Users/$adminaccount "dumbpassword"
dscl . -create /Users/$adminaccount UniqueID 501
dscl . -create /Users/$adminaccount PrimaryGroupID 80
dscl . -create /Users/$adminaccount UserShell /bin/bash
dscl . -create /Users/$adminaccount NFSHomeDirectory /Users/$adminaccount
scp -R /System/Library/User\ Template/English.lproj /Users/$adminaccount
chown -R $adminaccount:staff /Users/$adminaccount

dseditgroup -o edit -d admin -t group com.apple.access_ssh
dscl . append /Groups/com.apple.access_ssh user $adminaccount
dscl . append /Groups/com.apple.access_ssh GroupMembership $adminaccount
dscl . append /Groups/com.apple.access_ssh groupmembers `dscl . read /Users/$adminaccount GeneratedUID | cut -d " " -f 2`

# Setting up ARD for use of new account
systemsetup -setremotelogin on
System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -specifiedUsers
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -users $adminaccount -access -on -privs -DeleteFiles -ControlObserve -TextMessages -OpenQuitApps -GenerateReports -RestartShutDown -SendFiles -ChangeSettings
/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -activate -restart -console

exit 0
