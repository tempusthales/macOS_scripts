#!/bin/bash

/usr/bin/defaults write "/var/db/locationd/Library/Preferences/ByHost/com.apple.locationd" LocationServicesEnabled -bool true
/usr/sbin/chown -R _locationd:_locationd "/var/db/locationd"
/usr/bin/defaults write "/Library/Preferences/com.apple.timezone.auto" Active -bool true