#!/bin/bash

##################################################################################################################
# Name:                       dock_config_user_template.sh
# Purpose:                    Configures the default user template's default dock - will only modify
#                             the default user template of the current language of the computer
###################################################################################################################
# Establish standardized local logging logic
###################################################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.dock_setup.log"

logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d..%H:%M:%S-%z) 2>&1)"
  user="$((who -m | awk '{print $1;}') 2>&1)"
  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  else
    # write local logs
    echo "$date_set    $user    ${0##*/}    $1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  fi
}
###################################################################################################################
# Verify dockutil installation
###################################################################################################################
# create variable of dockutil location
dockutil="/usr/local/bin/dockutil"
# verify dockutil installation and exit with error if not found
if [[ -f "$dockutil" ]]; then
    dockutilVersion=$($dockutil --version)
    logMessage "dockutil version $dockutilVersion installed to $dockutil"
else
    logMessage "dockutil not found at $dockutil!"
    logMessage "Default company_name dock cannot be set"
    logMessage "Exiting with error..."
    exit 1
fi
###################################################################################################################
# Create launch agent to remove Apple persisten dock icons
###################################################################################################################

#####################################################################################
# Create /Library/.company_name/Scripts/ if needed
#####################################################################################
if [[ -d /Library/.company_name/Scripts/ ]]; then
  logMessage "/Library/.company_name/Scripts/ already exists"
else
  # create company_name Scripts directory and set ownership & permissions
  mkdir -p /Library/.company_name/Scripts/
  chown root:wheel /Library/.company_name/Scripts/
  chmod 755 /Library/.company_name/Scripts/
  if [[ -d /Library/.company_name/Scripts/ ]]; then
    logMessage "/Library/.company_name/Scripts/ created successfully"
  else
    logMessage "Failed to create /Library/.company_name/Scripts/"
    logMessage "Exiting with error..."
    exit 1
  fi
fi

logMessage "Writing /Library/.company_name/Scripts/dockfix.sh"
#create new /Library/.company_name/Scripts/dockfix.sh
cat > /Library/.company_name/Scripts/dockfix.sh << 'EOF'
#!/bin/bash
##################################################################################################################
# Name:                       dockfix.sh
# Purpose:                    Removes dock items placed by /System/Library/CoreServices/Dock.app/Contents/Resources/com.apple.dockfixup.plist
#                             during first login of every user on a computer - must be excecuted by Launch Agent (user)
##################################################################################################################
# Acquire variables related to user
##################################################################################################################
# get currently logged in user
currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
# get user's home folder
currentUserHome=$(dscl . -read /Users/$currentUser NFSHomeDirectory | cut -d " " -f 2)
###################################################################################################################
# Establish standardized local logging logic
###################################################################################################################
log_path="$currentUserHome/Library/.company_name/"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.dock_startup_fix.log"

logMessage () {

  mkdir -p $log_path

  date_set="$((date +%Y-%m-%d..%H:%M:%S-%z) 2>&1)"
  user="$((who -m | awk '{print $1;}') 2>&1)"
  if [[ "$log_file" == "" ]]; then
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  else
    # write local logs
    echo "$date_set    $user    ${0##*/}    $1" >> $log_path/$log_file
    # write to stdout (capture by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  fi
}
logMessage ""
logMessage "Starting script..."
###################################################################################################################
# Check if dockfix has been completed
###################################################################################################################
if [[ -f "$currentUserHome/Library/.company_name/.dockset_done" ]]; then
  logMessage ""
  logMessage "Found $currentUserHome/Library/.company_name/.dockset_done"
  logMessage "dock_startup_fix was completed for $currentUser on $(ls -alh "$currentUserHome/Library/.company_name/.dockset_done" | awk '{print $6,$7,$8}')"
  logMessage "Exiting."
  exit 0
else
  logMessage "$currentUserHome/Library/.company_name/.dockset_done not detected"
  logMessage "Proceeding with script..."
fi
###################################################################################################################
# Verify dockutil installation
###################################################################################################################
# create variable of dockutil location
dockutil="/usr/local/bin/dockutil"
# verify dockutil installation and exit with error if not found
if [[ -f "$dockutil" ]]; then
    dockutilVersion=$($dockutil --version)
    logMessage "dockutil version $dockutilVersion installed to $dockutil"
else
    logMessage "dockutil not found at $dockutil!"
    logMessage "Default company_name dock cannot be set"
    logMessage "Exiting with error..."
    exit 1
fi
###################################################################################################################
# Dockutil com.apple.dockfixup.plist remediation function
###################################################################################################################
dockutilRemove () {
  # set maximum wait time(seconds)/loop iterations
  maxIterations="10"
  i=0
  # wait for /System/Library/CoreServices/Dock.app/Contents/Resources/com.apple.dockfixup.plist to populate with $1
  while [[ $($dockutil --find $1 | grep "was not found in") != "" ]] && [[ "$i" -lt "$maxIterations" ]]; do
    logMessage "Iteration number: $i"
    logMessage "Dock has not been populated with $1"
    logMessage "Waiting..."
    sleep 1
    (( i++ ))
  done

  # set the dock if system took less than 20 seconds to set
  if [[ "$i" != "$maxIterations" ]]; then
    $dockutil --remove "$1" --no-restart
    if [[ $($dockutil --find $1 | grep "was not found in") != "" ]]; then
      logMessage "Successfully removed $1 from $currentUser's dock"
    else
      logMessage "Failed to remove $1 from $currentUser's dock!"
    fi
  # infom if 20 seconds elapsed without com.apple.dockfixup.plist populating dock
  else
    logMessage "$i seconds elapsed without com.apple.dockfixup.plist adding $1 to dock"
    logMessage "Please check system for issues"
    logMessage "Skipping removing $1 from $currentUser's dock"
  fi
}

dockutilRemove "News"
dockutilRemove "Maps"
dockutilRemove "Siri"
dockutilRemove "Photos"

# add ~/Documents and allow to restart dock
$dockutil --add "$currentUserHome/Documents" --view fan --display folder
if [[ $($dockutil --list | grep "$currentUserHome/Documents" | awk '{print $1') == "Documents" ]]; then
  logMessage "Added $currentUserHome/Documents foler to $currentUser's dock"
else
  logMessage "Failed to add ~/Documents to $currentUser's dock"
fi

# make placeholder file to stop dock_startup_fix.sh from running again
touch "$currentUserHome/Library/.company_name/.dockset_done"
if [[ -f "$currentUserHome/Library/.company_name/.dockset_done" ]]; then
  logMessage "$currentUserHome/Library/.company_name/.dockset_done placed to prevent future runs of this script for $currentUser"
  logMessage "Script complete. Exiting..."
  exit 0
else
  logMessage "Failed to create $currentUserHome/Library/.company_name/.dockset_done!"
  logMessage "This script may run at every login, please check endpoint for issues"
  logMessage "Exiting with error..."
  exit 2
fi


#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 3
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == dockutil was not found at $dockutil
# exit 2 == failed to create/verify $currentUserHome/Library/.company_name/.dockset_done
# exit 3 == arrived at end of script erroneously, check script for errors
EOF

# verify existence of /Library/.company_name/Scripts/dockfix.sh
if [[ -f "/Library/.company_name/Scripts/dockfix.sh" ]]; then
  logMessage "/Library/.company_name/Scripts/dockfix.sh was successfully created/modified on $(ls -alh /Library/.company_name/Scripts/dockfix.sh | awk '{print $6,$7,$8}')"
  logMessage "Setting permissions and ownership for /Library/.company_name/Scripts/dockfix.sh"
  # set permissions
  chmod 755 /Library/.company_name/Scripts/dockfix.sh
  #set ownership
  chown root:wheel /Library/.company_name/Scripts/dockfix.sh
else
  logMessage "Failed to create /Library/.company_name/Scripts/dockfix.sh!"
  exit 2
fi

logMessage "Writing /Library/LaunchAgents/com.company_name.dockfix.plist"
#create new /Library/LaunchAgents/com.company_name.dockfix.plist
cat > /Library/LaunchAgents/com.company_name.dockfix.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.company_name.dockfix</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Library/.company_name/Scripts/dockfix.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
EOF

# verify existence of /Library/LaunchAgents/com.company_name.dockfix.plist
if [[ -f "/Library/LaunchAgents/com.company_name.dockfix.plist" ]]; then
  logMessage "/Library/LaunchAgents/com.company_name.dockfix.plist was successfully created/modified on $(ls -alh /Library/LaunchAgents/com.company_name.dockfix.plist | awk '{print $6,$7,$8}')"
  logMessage "Setting permissions and ownership for /Library/LaunchAgents/com.company_name.dockfix.plist"
  # set permissions
  chmod 644 /Library/LaunchAgents/com.company_name.dockfix.plist
  #set ownership
  chown root:wheel /Library/LaunchAgents/com.company_name.dockfix.plist
else
  logMessage "Failed to create /Library/LaunchAgents/com.company_name.dockfix.plist!"
  exit 3
fi
##################################################################################################################
# Gather names of all default user template language folder names
##################################################################################################################
# assign direcories in /System/Library/User\ Template/ to an array
# set iterations variable to 0 runs
i=0
for directory in /System/Library/User\ Template/*.lproj/; do
    DUtemplates[ $i ]="$directory"
    (( i++ ))
done

logMessage ""
logMessage ""
# number of items in array
logMessage "${#DUtemplates[@]} default user template language directories found in /System/Library/User Template/..."
##################################################################################################################
# Master function for configuring the dock within a loop using ${DUtemplates[$i]}
##################################################################################################################
DUtemplateDockSet ()
{
##################################################################################################################
# Create placeholder ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist
##################################################################################################################
# inform if existing $language default dock exists
if [[ -f "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist" ]]; then
  logMessage "Existing dock exists in ${DUtemplates[$i]}"
  logMessage "Overwriting..."
fi

# make ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist if it does not exist
logMessage "Creating ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"

cat > "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>last-messagetrace-stamp</key>
	<real>574792871.61431301</real>
	<key>loc</key>
	<string>en_US</string>
	<key>mod-count</key>
	<integer>4</integer>
	<key>persistent-apps</key>
	<array>
		<dict>
			<key>GUID</key>
			<integer>1632544036</integer>
			<key>tile-data</key>
			<dict>
				<key>book</key>
				<data>
				Ym9va+QCAAAAAAQQMAAAAAAAAAAAAAAAAAAAAAAAAAAA
				AAAAAAAAAAAAAAAAAAAABAIAAAwAAAABAQAAQXBwbGlj
				YXRpb25zDQAAAAEBAABMYXVuY2hwYWQuYXBwAAAACAAA
				AAEGAAAEAAAAGAAAAAgAAAAEAwAAFQEAAAAAAAAIAAAA
				BAMAANhnAAAAAAAACAAAAAEGAABAAAAAUAAAAAgAAAAA
				BAAAQcCT2c+AAAAYAAAAAQIAAAIAAAAAAAAADwAAAAAA
				AAAAAAAAAAAAAAgAAAABCQAAZmlsZTovLy8UAAAAAQEA
				AEphbWYtRGV2LVRlc3QtRW5yb2xsCAAAAAQDAAAAUAZe
				OgAAAAgAAAAABAAAQcES0fG3NqwkAAAAAQEAADNGREIz
				QzM5LTAzNkEtNEU5Ri05REVFLUI4RjUyMTQ3QzRDRRgA
				AAABAgAAgQAAAAEAAADvEwAAAQAAAAAAAAAAAAAAAQAA
				AAEBAAAvAAAAAAAAAAEFAACvAAAAAQIAADM4MWM0ZjNm
				ZTQ2NDQ4ZTdkNDBjMjg5N2UyYTU4NGIzYzkwYmI5OWU7
				MDA7MDAwMDAwMDA7MDAwMDAwMDA7MDAwMDAwMDA7MDAw
				MDAwMDAwMDAwMDAxYTtjb20uYXBwbGUuYXBwLXNhbmRi
				b3gucmVhZDswMTswMTAwMDAwNzswMDAwMDAwMDAwMDA2
				N2Q4OzA1Oy9hcHBsaWNhdGlvbnMvbGF1bmNocGFkLmFw
				cAAAqAAAAP7///8BAAAAAAAAAA0AAAAEEAAAMAAAAAAA
				AAAFEAAAYAAAAAAAAAAQEAAAgAAAAAAAAABAEAAAcAAA
				AAAAAAACIAAAOAEAAAAAAAAFIAAAoAAAAAAAAAAQIAAA
				sAAAAAAAAAARIAAA7AAAAAAAAAASIAAAzAAAAAAAAAAT
				IAAA3AAAAAAAAAAgIAAAGAEAAAAAAAAwIAAARAEAAAAA
				AACB8AAATAEAAAAAAAA=
				</data>
				<key>bundle-identifier</key>
				<string>com.apple.launchpad.launcher</string>
				<key>dock-extra</key>
				<false/>
				<key>file-data</key>
				<dict>
					<key>_CFURLString</key>
					<string>file:///Applications/Launchpad.app/</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-label</key>
				<string>Launchpad</string>
				<key>file-mod-date</key>
				<integer>3617402015</integer>
				<key>file-type</key>
				<integer>169</integer>
				<key>parent-mod-date</key>
				<integer>241556891025639</integer>
			</dict>
			<key>tile-type</key>
			<string>file-tile</string>
		</dict>
		<dict>
			<key>GUID</key>
			<integer>1632544050</integer>
			<key>tile-data</key>
			<dict>
				<key>book</key>
				<data>
				Ym9va/QCAAAAAAQQMAAAAAAAAAAAAAAAAAAAAAAAAAAA
				AAAAAAAAAAAAAAAAAAAAFAIAAAwAAAABAQAAQXBwbGlj
				YXRpb25zFgAAAAEBAABTeXN0ZW0gUHJlZmVyZW5jZXMu
				YXBwAAAIAAAAAQYAAAQAAAAYAAAACAAAAAQDAAAVAQAA
				AAAAAAgAAAAEAwAAXBcBAAAAAAAIAAAAAQYAAEgAAABY
				AAAACAAAAAAEAABBwJPcdwAAABgAAAABAgAAAgAAAAAA
				AAAPAAAAAAAAAAAAAAAAAAAACAAAAAEJAABmaWxlOi8v
				LxQAAAABAQAASmFtZi1EZXYtVGVzdC1FbnJvbGwIAAAA
				BAMAAABQBl46AAAACAAAAAAEAABBwRLR8bc2rCQAAAAB
				AQAAM0ZEQjNDMzktMDM2QS00RTlGLTlERUUtQjhGNTIx
				NDdDNENFGAAAAAECAACBAAAAAQAAAO8TAAABAAAAAAAA
				AAAAAAABAAAAAQEAAC8AAAAAAAAAAQUAALgAAAABAgAA
				YTQ0OTc2Zjg4ZDg2NmI1NDY1YmM5YmI5YmM0NTVjMWFl
				ZTg5M2E4MDswMDswMDAwMDAwMDswMDAwMDAwMDswMDAw
				MDAwMDswMDAwMDAwMDAwMDAwMDFhO2NvbS5hcHBsZS5h
				cHAtc2FuZGJveC5yZWFkOzAxOzAxMDAwMDA3OzAwMDAw
				MDAwMDAwMTE3NWM7MDU7L2FwcGxpY2F0aW9ucy9zeXN0
				ZW0gcHJlZmVyZW5jZXMuYXBwAKgAAAD+////AQAAAAAA
				AAANAAAABBAAADgAAAAAAAAABRAAAGgAAAAAAAAAEBAA
				AIgAAAAAAAAAQBAAAHgAAAAAAAAAAiAAAEABAAAAAAAA
				BSAAAKgAAAAAAAAAECAAALgAAAAAAAAAESAAAPQAAAAA
				AAAAEiAAANQAAAAAAAAAEyAAAOQAAAAAAAAAICAAACAB
				AAAAAAAAMCAAAEwBAAAAAAAAgfAAAFQBAAAAAAAA
				</data>
				<key>bundle-identifier</key>
				<string>com.apple.systempreferences</string>
				<key>dock-extra</key>
				<true/>
				<key>file-data</key>
				<dict>
					<key>_CFURLString</key>
					<string>file:///Applications/System%20Preferences.app/</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-label</key>
				<string>System Preferences</string>
				<key>file-mod-date</key>
				<integer>3617403374</integer>
				<key>file-type</key>
				<integer>41</integer>
				<key>parent-mod-date</key>
				<integer>241556891025639</integer>
			</dict>
			<key>tile-type</key>
			<string>file-tile</string>
		</dict>
	</array>
	<key>persistent-others</key>
	<array>
		<dict>
			<key>GUID</key>
			<integer>1632544051</integer>
			<key>tile-data</key>
			<dict>
				<key>arrangement</key>
				<integer>2</integer>
				<key>book</key>
				<data>
				Ym9va0ADAAAAAAQQMAAAAAAAAAAAAAAAAAAAAAAAAAAA
				AAAAAAAAAAAAAAAAAAAAPAIAAAUAAAABAQAAVXNlcnMA
				AAACAAAAAQEAAGZmAAAJAAAAAQEAAERvd25sb2FkcwAA
				AAwAAAABBgAABAAAABQAAAAgAAAACAAAAAQDAADDqAoA
				AAAAAAgAAAAEAwAAyrwTAAAAAAAIAAAABAMAANm8EwAA
				AAAADAAAAAEGAABIAAAAWAAAAGgAAAAIAAAAAAQAAEG+
				/b6TAAAAGAAAAAECAAACAAAAAAAAAA8AAAAAAAAAAAAA
				AAAAAAAIAAAABAMAAAEAAAAAAAAABAAAAAMDAAD4AQAA
				CAAAAAEJAABmaWxlOi8vLxQAAAABAQAASmFtZi1EZXYt
				VGVzdC1FbnJvbGwIAAAABAMAAABQBl46AAAACAAAAAAE
				AABBwRLR8bc2rCQAAAABAQAAM0ZEQjNDMzktMDM2QS00
				RTlGLTlERUUtQjhGNTIxNDdDNENFGAAAAAECAACBAAAA
				AQAAAO8TAAABAAAAAAAAAAAAAAABAAAAAQEAAC8AAAAA
				AAAAAQUAAK0AAAABAgAAOWYxMmQ5MTFhMGUyMzdmMTg0
				YmU3NDUwYWE2MzJlMzMyMjViMTVlMTswMDswMDAwMDAw
				MDswMDAwMDAwMDswMDAwMDAwMDswMDAwMDAwMDAwMDAw
				MDIwO2NvbS5hcHBsZS5hcHAtc2FuZGJveC5yZWFkLXdy
				aXRlOzAxOzAxMDAwMDA3OzAwMDAwMDAwMDAxM2JjZDk7
				MDE7L3VzZXJzL2ZmL2Rvd25sb2FkcwAAAADMAAAA/v//
				/wEAAAAAAAAAEAAAAAQQAAA0AAAAAAAAAAUQAAB4AAAA
				AAAAABAQAACcAAAAAAAAAEAQAACMAAAAAAAAAAIgAABw
				AQAAAAAAAAUgAADYAAAAAAAAABAgAADoAAAAAAAAABEg
				AAAkAQAAAAAAABIgAAAEAQAAAAAAABMgAAAUAQAAAAAA
				ACAgAABQAQAAAAAAADAgAAB8AQAAAAAAAAHAAAC8AAAA
				AAAAABHAAAAUAAAAAAAAABLAAADMAAAAAAAAAIDwAACE
				AQAAAAAAAA==
				</data>
				<key>displayas</key>
				<integer>0</integer>
				<key>file-data</key>
				<dict>
					<key>_CFURLString</key>
					<string>file:///Users/ff/Downloads/</string>
					<key>_CFURLStringType</key>
					<integer>15</integer>
				</dict>
				<key>file-label</key>
				<string>Downloads</string>
				<key>file-mod-date</key>
				<integer>2975753313599</integer>
				<key>file-type</key>
				<integer>2</integer>
				<key>parent-mod-date</key>
				<integer>258715285986722</integer>
				<key>preferreditemsize</key>
				<integer>-1</integer>
				<key>showas</key>
				<integer>1</integer>
			</dict>
			<key>tile-type</key>
			<string>directory-tile</string>
		</dict>
	</array>
	<key>recent-apps</key>
	<array/>
	<key>region</key>
	<string>US</string>
	<key>version</key>
	<integer>1</integer>
</dict>
</plist>
EOF

# verify that ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist was created
# exit with failure if not
if [[ ! -f "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist" ]]; then
  logMessage ""
  logMessage "Failed to create ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist!"
  logMessage "Error logged..."
  logMessage ""
else
  logMessage "Successfully created dock placeholder file ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  # set ownership and permissions ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist
  logMessage "Setting ownership and permissions for ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  chown root:wheel "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  chmod 600 "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
fi

##################################################################################################################
# Configure dock
##################################################################################################################
# function to add $1 (application name) to $2 (position) in the default user template's dock
dockutilAdd () {
  $dockutil --add "/Applications/$1.app" --no-restart --position $2 "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  if [[ $($dockutil --find $1 | grep "was not found in") == "" ]]; then
    logMessage "Added $1 to position $2 in ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  else
    logMessage "Failed to add $1 to ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"
  fi
}

# clearing placeholder dock
logMessage "Clearing existing/placeholder dock in ${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist..."
$dockutil --remove all --no-restart "${DUtemplates[$i]}Library/Preferences/com.apple.dock.plist"

# add System Preferences
dockutilAdd "System Preferences" "1"

# add Launchpad
dockutilAdd "Launchpad" "2"

# add Safari
dockutilAdd "Safari" "3"

# add Google Chrome
dockutilAdd "Google Chrome" "4"

# add Calculator
dockutilAdd "Calculator" "5"

# add Calculator
dockutilAdd "company_name Self Service" "5"

# add Skype for Business
dockutilAdd "Skype for Business" "7"

# add Microsoft Excel
dockutilAdd "Microsoft Excel" "8"

# add Microsoft Outlook
dockutilAdd "Microsoft Outlook" "9"

# add Microsoft Powerpoint
dockutilAdd "Microsoft Powerpoint" "10"

# add Microsoft Word
dockutilAdd "Microsoft Word" "11"

# add Cisco Anyconnect if computer is portable
if [[ $(sysctl -n hw.model | grep "Book") != "" ]]; then
  logMessage "Computer is a portable - adding portable-specific items.."
  dockutilAdd "VPN Client" "12"
fi

logMessage "Run interation $i complete"
# make variable to display next iteration number
let "iPlus = $i + 1"

if [[ "$iPlus" -lt ${#DUtemplates[@]} ]]; then
  logMessage "Completed dock confguration for ${DUtemplates[$i]}"
  logMessage "procceding to run iteration $iPlus..."
  logMessage ""
else
  logMessage "${DUtemplates[$i]} was the last default user template to modify"
  logMessage ""
fi
}
#####################################################################################
# Run loop to set each dock per ${DUtemplates[$i]}
#####################################################################################
# set iterations variable to 0 runs
i=0
# run as many loops of setting default user template docks as required by total # of lproj folders
while [[ "$i" -lt ${#DUtemplates[@]} ]]; do
  logMessage ""
  logMessage "Run iteration:                $i"
  logMessage "Target Default User Template: ${DUtemplates[$i]}"

  # run function to set current default user template dock based on ${DUtemplates[$i]}
  DUtemplateDockSet
  # add 1 to the IFS
  (( i++ ))
done

logMessage "Script completed successfully"
logMessage "Exiting..."
exit 0
#####################################################################################
# Erroneous completion
#####################################################################################
# if the script proceeds here, check recent coding changes for errors
logMessage "Erroneously arrived at end of script..."
exit 4
#####################################################################################
# Exit codes
#####################################################################################
# exit 0 == successful run
# exit 1 == dockutil was not found at $dockutil
# exit 2 == failed to create /Library/.company_name/Scripts/dockfix.sh
# exit 3 == failed to create /Library/LaunchAgents/com.company_name.dockfix.plist
# exit 4 == arrived at end of script erroneously, check script for errors
