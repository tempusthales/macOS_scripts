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

if softwareupdate -i $getosupd | grep "restart" ; then

sudo /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType utility -title "WARNING" -description "$MSG1" -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns -iconSize 96 -button1 "OK" -defaultButton 1

fi

# Install Security updates
if softwareupdate -i $getsecupd | grep "restart" ; then 

sudo /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType utility -title "WARNING" -description "$MSG2" -icon /System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertCautionIcon.icns -iconSize 96 -button1 "OK" -defaultButton 1

fi

exit 0