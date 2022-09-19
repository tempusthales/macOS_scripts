#!/bin/bash

/usr/bin/caffeinate -st 600 &

/bin/launchctl unload -w /Library/LaunchDaemons/com.filewave.fwcld.plist
/bin/sleep 10
/bin/launchctl load -w /Library/LaunchDaemons/com.filewave.fwcld.plist

exit 0