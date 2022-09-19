#!/bin/bash

# Run this tool before beginning a user migration.  When finished run the tool user_migration_tool_step2.sh

loggedInUser=`python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; loggedInUser = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; loggedInUser = [loggedInUser,""][loggedInUser in [u"loginwindow", None, u""]]; sys.stdout.write(loggedInUser + "\n");'`

sudo dseditgroup -o edit -d admin -t group com.apple.access_ssh
sudo dscl . append /Groups/com.apple.access_ssh user $loggedInUser
sudo dscl . append /Groups/com.apple.access_ssh GroupMembership $loggedInUser
sudo dscl . append /Groups/com.apple.access_ssh groupmembers `dscl . read /Users/$loggedInUser GeneratedUID | cut -d " " -f 2`

exit 0