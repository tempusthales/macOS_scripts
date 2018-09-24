#!/bin/bash

### Environment Variables ###

# For OS updates use OSXUpd
# For Security updates use SecUpd

# Get any OS updates
getosupd=$(softwareupdate -l | grep OSXUpd | awk 'NR==1 {print $2}')

# Get any security updates
getsecupd=$(softwareupdate -l | grep SecUpd | awk 'NR==1 {print $2}')

### DO NOT MODIFY BELOW THIS LINE ###

MSG1='OS Software updates have been installed and require a restart. Please save your work and restart your machine'
MSG2='Security updates have been installed and require a restart. Please save your work and restart your machine'

# Install OS updates
# This portion uses Sheag Craig's Yo! Notifications you can get it here: https://github.com/sheagcraig/yo

if softwareupdate -i $getosupd | grep "restart" ; then

sudo open yo_scheduler.app -t "WARNING" -s "$MSG1" -i "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns" -d -b "OK"

fi

# Install Security updates
if softwareupdate -i $getsecupd | grep "restart" ; then 

sudo open yo_scheduler.app -t "WARNING" -s "$MSG2" -i "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns" -d -b "OK"

fi

exit 0