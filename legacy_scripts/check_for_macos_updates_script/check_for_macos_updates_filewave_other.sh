#!/bin/bash

### Environment Variables ###

# This script is designed to work with manual pushes or Filewave or Munki.  It does require the use of Shea Craig's Yo! Notifications
# that you can get here: https://github.com/sheagcraig/yo.  You could use the CocoaDialog Notifications from https://cocoadialog.com/
# but you would need to adapt it yourself, but should be easy to do (if you know what you are doing...)

# ------

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

if softwareupdate -i $getosupd | grep "restart" ; then

sudo open yo_scheduler.app -t "WARNING" -s "$MSG1" -i "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns" -d -b "OK"

fi

# Install Security updates
if softwareupdate -i $getsecupd | grep "restart" ; then 

sudo open yo_scheduler.app -t "WARNING" -s "$MSG2" -i "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns" -d -b "OK"

fi

exit 0