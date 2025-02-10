#!/bin/bash

##################################################################################################################
# Name:                       configure_outlook_setup.sh
# Purpose:                    Configures the components that makeup the Outlook setup process.  
# Important:		      This script is based on the work done by William Smith (Talkingmoose)
#                             https://github.com/talkingmoose/Outlook-Exchange-Setup-5
###################################################################################################################
# Establish standardized local logging logic
###################################################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.configure.outlook.setup.log"

logMessage() {
  # Ensure log_path is set
  [ -z "$log_path" ] && log_path="/var/log/default"

  mkdir -p "$log_path"

  # Correct command substitution
  date_set="$(date +%Y-%m-%d..%H:%M:%S-%z 2>&1)"
  user="$(who -m | awk '{print $1;}' 2>&1)"

  if [[ -z "$log_file" ]]; then
    # Write to stdout (captured by Jamf script logging)
    echo "$date_set    $user    ${0##*/}    $1"
  else
    # Write to local logs
    echo "$date_set    $user    ${0##*/}    $1" >> "$log_path/$log_file"
    # Also write to stdout
    echo "$date_set    $user    ${0##*/}    $1"
  fi
}


#####################################################################################
# Create if LaunchAgent com.company_name.OutlookExchangeSetup.plist if needed
#####################################################################################
if [ -f "/Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist" ]; then

	logMessage "LaunchAgent com.company_name.OutlookExchangeSetup.plist exists. Skipping..."
	
else

	logMessage "Creating com.company_name.OutlookExchangeSetup.plist LaunchAgent."

	# Create LaunchAgent
	cat > "/Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist" <<-'EOF' 
	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>Disabled</key>
		<false/>
		<key>EnvironmentVariables</key>
		<dict>
			<key>PATH</key>
			<string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/Server.app/Contents/ServerRoot/usr/bin:/Applications/Server.app/Contents/ServerRoot/usr/sbin:/usr/local/sbin</string>
		</dict>
		<key>Label</key>
		<string>com.company_name.OutlookExchangeSetupLaunchAgent</string>
		<key>ProgramArguments</key>
		<array>
			<string>/bin/sh</string>
			<string>/Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh</string>
		</array>
		<key>RunAtLoad</key>
		<true/>
	</dict>
	</plist>
	EOF

	chmod 644 "/Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist"
	chown root:wheel "/Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist"
	
	if [ -f "/Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist" ]; then
		logMessage "LaunchAgent com.company_name.OutlookExchangeSetup.plist created successfully."
	else
		logMessage "Error creating com.company_name.OutlookExchangeSetup.plist."
		logMessage "Exiting with error..."
		exit 1
		
	fi	
fi

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

#####################################################################################
# Create script file for LaunchAgent /Library/LaunchAgents/com.company_name.OutlookExchangeSetup.plist
#####################################################################################
logMessage "Writing /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh"
# Create new /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh

cat > /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh <<-'EOF'

#!/bin/bash

##################################################################################################################
# Name:                       outlook_exchange_setup.sh
# Purpose:                    Configures company_name user Outlook Exchange account.                     
###################################################################################################################
# Get current logged in user
###################################################################################################################
currentUser=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')
###################################################################################################################
# Establish standardized local logging logic
###################################################################################################################
log_path="/Users/$currentUser/Library/Logs"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.outlook.exchange.setup.log"

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

LogMsg()
{
	while read IN
	do
		logMessage "$IN"
	done
}

###################################################################################################################
# Function to setup Outlook mailbox.
###################################################################################################################

setupOutlookAccount () {

###################################################################################################################
# Begins to configure MS container folders.
###################################################################################################################
if [[ ! -d "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office" ]] ; then
	logMessage "Folder \"/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office\" does not exist."
	
	/bin/mkdir -p "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office"
	if [ $? = 0 ] ; then
	  logMessage "Create folder \"/Users/$currentUser/Library/Group Containters/UBF8T346G9.Office\": Successful."
	else
	  logMessage "Create folder \"/Users/$currentUser/Library/Group Containters/UBF8T346G9.Office\": Failed."
	fi
	 
	/usr/bin/touch "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist"
	if [ $? = 0 ] ; then
	  logMessage "Create empty file \"/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist\": Successful."
	else
	  logMessage "Create empty file \"/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist\": Failed."
	fi
	
	/usr/bin/osascript 2>&1 <<-EOF1 | LogMsg

	property errorMessage : "Outlook's setup for your Exchange account failed. Please contact the Help Desk for assistance."

	tell application "Microsoft Outlook"
		activate
		delay 2
		close (every window whose name is "Set Up Your Email")
	
		try
			set working offline to true
			log "Set Microsoft Outlook to work offline: Successful."
		on error
			log "Set Microsoft Outlook to work offline: Failed."
		end try

		try
			set group similar folders to false
			log "Set Group Similar Folders to false: Successful."
		on error
			log "Set Group Similar Folders to false: Failed."
		end try

		try
			set hide on my computer folders to false
			log "Set Hide On My Computer Folders to false: Successful."
		on error
			log "Set Hide On My Computer Folders to false: Failed."
		end try

		-- create the Exchange account
		--log "$userFullName"
		--log "$domainPrefix"
		--log "$userShortName"
		--set domainUser to "user name: " & "$domainPrefix" & "\\" & "$userShortName"
		--log " & domainUser & "
	
		try
			set newExchangeAccount to make new exchange account with properties ¬
				{name:"Mailbox - $userFullName", domain:"$domainPrefix", user name:"$userShortName", full name:"$userFullName", email address:"$emailAddress", server:"$ExchangeServer", use ssl:true, port:"443", ldap server:"$DirectoryServer", ldap needs authentication:true, ldap use ssl:false, ldap port:"3268", ldap max entries:1000, ldap search base:"", receive partial messages:false, background autodiscover:true}
			log "Create Exchange account: Successful."
		on error
	
			-- something went wrong
	
			log "Create Exchange account: Failed."
	
			display dialog errorMessage & return & return & "Unable to create Exchange account." with icon stop buttons {"OK"} default button {"OK"} with title "Outlook Exchange Setup"
			error number -128
	
		end try
	
		try
			-- The Me Contact record is automatically created with the first account.
			-- Set the first name, last name, email address and other information using Active Directory.
	
			set first name of me contact to "$userFirstName"
			set last name of me contact to "$userLastName"
			set email addresses of me contact to {address:"$emailAddress", type:work}
			log "Populate Me Contact information: Successful."
		on error
			log "Populate Me Contact information: Failed."
		end try

		-- Set Outlook to be the default application
		-- for mail, calendars and contacts.

		try
			set system default mail application to true
			set system default calendar application to true
			set system default address book application to true
			log "Set Outlook as default mail, calendar and contacts application: Successful."
		on error
			log "Set Outlook as default mail, calendar and contacts application: Failed."
		end try

		delay 5

		try
			set working offline to false
			log "Set Microsoft Outlook to work online: Successful."
		on error
			log "Set Microsoft Outlook to work online: Failed."
		end try
	
		-- Done
	
	end tell

	EOF1

else
	if [[ -d "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office" ]] ; then
		logMessage "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office folder already exists. Doing nothing." 
	else	
		logMessage "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office folder does not exist but it should exist already. Something may be wrong."
	fi
	
	if [[ -f "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist" ]] ; then
		logMessage "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist already exists. Doing nothing."
	else	
		logMessage "/Users/$currentUser/Library/Group Containers/UBF8T346G9.Office/OutlookProfile.plist does not exist but it should exist already. Something may be wrong."
	fi
fi
}

logMessage "***Start MS Outlook Setup***"
###################################################################################################################
# Determines if logged in user is a local account; if so, exit; if not, continue
###################################################################################################################
if [ -z "$(/usr/bin/dscl . read /Users/$currentUser OriginalNodeName 2>/dev/null)" ]; then
  logMessage "Local account. Exiting."
  exit 1
else
  logMessage "AD User logged in, continuing script."
fi

###################################################################################################################
# Gets all needed data to setup Outlook email.
###################################################################################################################
userShortName="$currentUser"
logMessage "userShortName: $userShortName"
userFirstName=$(/usr/bin/dscl . read /Users/$currentUser FirstName | sed 's/FirstName://g' | sed -e 's/^[[:space:]]*//' | sed '/^[[:space:]]*$/d')
logMessage "userFirstName: $userFirstName"
userLastName=$(/usr/bin/dscl . read /Users/$currentUser LastName  | sed 's/LastName://g' | sed -e 's/^[[:space:]]*//' | sed '/^[[:space:]]*$/d')
logMessage "userLastName: $userLastName"
userFullName=$(/usr/bin/dscl . read /Users/$currentUser RealName | sed 's/RealName://g' | sed -e 's/^[[:space:]]*//' | sed '/^[[:space:]]*$/d')
logMessage "userFullName: $userFullName"
emailAddress=$(/usr/bin/dscl . read /Users/$currentUser EMailAddress | sed 's/EMailAddress://g' | sed -e 's/^[[:space:]]*//' | sed '/^[[:space:]]*$/d')
logMessage "emailAddress: $emailAddress"
domainPrefix=$(/usr/bin/dscl . read /Users/$currentUser | grep 'PrimaryNTDomain' | awk '{ print $2 }')
logMessage "domainPrefix: $domainPrefix"
ExchangeServer="autodiscovery.company_namemail.net"
DirectoryServer="msgdcsw007.msg.net"

###################################################################################################################
# Check to make sure all data needed for account is present.
###################################################################################################################
if [[ ! $userShortName ]] && [[ ! $userFirstName ]] && [[ ! $userLastName ]] && [[ ! $userFullName ]] && [[ ! $emailAddress ]] && [[ ! $domainPrefix ]]; then
	logMessage "Information to setup MS Outlook is missing. Exiting."
	exit 1
else
	logMessage "Information to setup MS Outlook present, continuing."
	setupOutlookAccount
fi
	
logMessage "***End MS Outlook Setup***"

EOF

chown root:admin /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh
chmod 755 /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh
chmod +x /Library/.company_name/Scripts/CCB-099_outlook_exchange_setup.sh

