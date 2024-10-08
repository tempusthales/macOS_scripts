#!/bin/bash

# Author: Tempus Thales
# Contributors
# Date: 10-08-2024
# Version: 2024-10-0.1
# Description: Script to display the JAMF LAPS account and password

#########################################################################################
#
# JAMF Script Variables
# $4: JSS URL
# $5: Encoded API Credentials
# $6: Slack URL
# $7: Teams URL
# $8: Service Desk URL
#
#########################################################################################

############################################################################
# Debug Mode - Change to 1 if you wish to run the script in Debug mode
############################################################################

DEBUG="0"

############################################################################
# Variables
############################################################################

JAMFLAPSLOG="/Library/.LAPS/Logs/JAMFLAPS.log"
CURRENT_USER=$(ls -l /dev/console | awk '{ print $3 }')
DEVICE=`hostname`
SERVICEDESK=$8

##############################################################
# dialogCheck - Thanks @acodega in MacAdmins Slack (SwiftDialog created by Bart Reardon https://github.com/bartreardon/swiftDialog)
##############################################################

function dialogCheck(){
	# Get the URL of the latest PKG From the Dialog GitHub repo
	dialogURL=$(curl --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	# Expected Team ID of the downloaded PKG
	expectedDialogTeamID="PWA5E9TQ59"
	
	# Check for Dialog and install if not found
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		echo "Dialog not found. Installing..."
		# Create temporary working directory
		workDirectory=$( /usr/bin/basename "$0" )
		tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		# Download the installer package
		/usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
		# Verify the download
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		# Install the package if Team ID validates
		if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
			/usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
			# else # uncomment this else if you want your script to exit now if swiftDialog is not installed
			# displayAppleScript # uncomment this if you're using my displayAppleScript function
			# echo "Dialog Team ID verification failed."
			# exit 1
		fi
		# Remove the temporary working directory when done
		/bin/rm -Rf "$tempDirectory"  
	else echo "Dialog found. Proceeding..."
	fi
}

##############################################################
# Check if SwiftDialog is installed 
##############################################################

dialogCheck

############################################################################
# API Credentials
############################################################################

# Get Bearer token
URL="$4"
password="$5"

token=$(curl -s -H "Content-Type: application/json" -H "Authorization: Basic ${password}" -X POST "$URL/api/v1/auth/token" | plutil -extract token raw -)

if [[ $DEBUG == "1" ]]; then
	echo "-----DEBUG MODE ENABLED-----" | tee -a "$JAMFLAPSLOG"
fi
if [[ $DEBUG == "1" ]]; then
	echo "-----DEBUG MODE----- Bearer Token: $token" | tee -a "$JAMFLAPSLOG"
fi

############################################################################
# Pop up for Device name
############################################################################

message=$(dialog \
--title "JAMF LAPS UI" \
--icon "https://i.imgur.com/Y3HzonC.png" --iconsize 100 \
--message "Please enter the name or serial of the device you wish to see the LAPS password for. \n\n You must also provide a reason for viewing the LAPS Password for auditing." \
--messagefont "name=Arial,size=17" \
--button1text "Continue" \
--button2text "Quit" \
--vieworder "dropdown,textfield" \
--textfield "LAPS Account",prompt="LAPS Account name if known" \
--textfield "Device,required" \
--textfield "Reason,required" \
--selecttitle "Serial or Hostname",required \
--selectvalues "Serial Number,Hostname" \
--selectdefault "Hostname" \
--ontop \
--regular \
--json \
--moveable
)
			
			DROPDOWN=$(echo $message | awk -F '"SelectedOption" : "' '{print$2}' | awk -F '"' '{print$1}')	
			name1=$(echo $message | awk -F '"Device" : "' '{print$2}' | awk -F '"' '{print$1}')
			reason=$(echo $message | awk -F '"Reason" : "' '{print$2}' | awk -F '"' '{print$1}') # Thanks to ons-mart https://github.com/ons-mart
			LAPSname=$(echo $message | awk -F '"LAPS Account" : "' '{print$2}' | awk -F '"' '{print$1}')
			
			if [[ $name1 == "" ]] || [[ $reason == "" ]]; then
				echo "Aborting"
				exit 1
			fi
			
			if [[ $DEBUG == "1" ]]; then
				echo "-----DEBUG MODE----- Device Type: $DROPDOWN" | tee -a "$JAMFLAPSLOG"
				echo "-----DEBUG MODE----- Device name: $name1" | tee -a "$JAMFLAPSLOG"
				echo "-----DEBUG MODE----- Viewed Reason: $reason" | tee -a "$JAMFLAPSLOG"
				echo "-----DEBUG MODE----- LAPS Name: $LAPSname" | tee -a "$JAMFLAPSLOG"
			fi
			
			############################################################################
			# Get Device ID
			############################################################################
			
			if [[ $DROPDOWN == "Hostname" ]]; then 
				echo "User selected Hostname"
				
				name=$(echo $name1 | sed -e 's#’#%E2%80%99#g' -e 's# #%20#g')
				
				# Get Device ID
				ID=$(curl -s -X GET "$URL/JSSResource/computers/name/$name" -H 'Accept: application/json' -H "Authorization:Bearer ${token}" | plutil -extract "computer"."general"."id" raw -)
			else
				echo "User selected Serial"
				
				# Get Device ID
				ID=$(curl -s -X GET "$URL/JSSResource/computers/serialnumber/$name1" -H 'Accept: application/json' -H "Authorization:Bearer ${token}" | plutil -extract "computer"."general"."id" raw -)
			fi
			
			if [[ $DEBUG == "1" ]]; then
				echo "-----DEBUG MODE----- JAMF ID: $ID" | tee -a "$JAMFLAPSLOG"
			fi
			
			############################################################################
			# Get JAMF Management ID
			############################################################################
			
			MANAGEID=$(curl -s -X "GET" "$URL/api/v1/computers-inventory-detail/$ID" -H "Accept: application/json" -H "Authorization:Bearer ${token}" | plutil -extract "general"."managementId" raw -)
			
			if [[ $DEBUG == "1" ]]; then
				echo "-----DEBUG MODE----- Managed ID: $MANAGEID" | tee -a "$JAMFLAPSLOG"
			fi
			
			############################################################################
			# Get LAPS Username
			############################################################################
			
			if [[ $LAPSname == "" ]]; then
				LAPSUSER=$(curl -s -X "GET" "$URL/api/v2/local-admin-password/$MANAGEID/accounts" -H "Accept: application/json" -H "Authorization:Bearer ${token}" | plutil -extract "results".0."username" raw -)
				############################################################################
				# Get Password
				############################################################################
				
				PASSWD=$(curl -s -X "GET" "$URL/api/v2/local-admin-password/$MANAGEID/account/$LAPSUSER/password" -H "Accept: application/json" -H "Authorization:Bearer ${token}" | plutil -extract password raw -)
			else
				LAPSUSER=$LAPSname
				
				############################################################################
				# Get Password
				############################################################################
				
				PASSWD=$(curl -s -X "GET" "$URL/api/v2/local-admin-password/$MANAGEID/account/$LAPSUSER/password" -H "Accept: application/json" -H "Authorization:Bearer ${token}" | plutil -extract password raw -)
			fi
			
			if [[ $DEBUG == "1" ]]; then
				echo "-----DEBUG MODE----- LAPS Account: $LAPSUSER" | tee -a "$JAMFLAPSLOG"
			fi
			
			############################################################################
			# View LAPS Account and Password
			############################################################################
			
			dialog \
			--title "JAMF LAPS UI" \
			--icon "https://i.imgur.com/W5PzhBr.png" --iconsize 100 \
			--message "The JAMF LAPS Account details for $name1 are:  \n\n Username: $LAPSUSER  \n Password: $PASSWD \n\n This message will close after 10seconds." \
			--messagefont "name=Arial,size=17" \
			--timer \
			--ontop \
			--moveable
			
			############################################################################
			# Slack notification
			############################################################################
			
			if [[ $6 == "" ]]; then
				echo "No slack URL configured"
			else
				if [[ $SERVICEDESK == "" ]]; then
					SERVICEDESK="https://www.slack.com"
				fi
				echo "Sending Slack WebHook"
				curl -s -X POST -H 'Content-type: application/json' \
				-d \
				'{
	"blocks": [
		{
			"type": "header",
			"text": {
				"type": "plain_text",
				"text": "JAMF LAPS Password Requested:closed_lock_with_key:",
			}
		},
		{
			"type": "divider"
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": ">*Device Name:*\n>'"$name1"'"
				},
				{
					"type": "mrkdwn",
					"text": ">*Requested by:*\n>'"$CURRENT_USER"' on '"$DEVICE"'"
				},
				{
					"type": "mrkdwn",
					"text": ">*Reason for Request:*\n>'"$reason"'"
				},
			]
		},
		{
		"type": "actions",
			"elements": [
				{
					"type": "button",
					"text": {
						"type": "plain_text",
						"text": "Challenge Request",
						"emoji": true
					},
					"style": "danger",
					"action_id": "actionId-0",
					"url": "'"$SERVICEDESK"'"
				}
			]
		}
	]
}' \
				$6
			fi
			
			############################################################################
			# Teams notification (Credit to https://github.com/nirvanaboi10 for the Teams code)
			############################################################################
			
			if [[ $7 == "" ]]; then
				echo "No teams Webhook configured"
			else
				if [[ $SERVICEDESK == "" ]]; then
					SERVICEDESK="https://www.microsoft.com/en-us/microsoft-teams/"
				fi
				echo "Sending Teams WebHook"
				jsonPayload='{
	"@type": "MessageCard",
	"@context": "http://schema.org/extensions",
	"themeColor": "0076D7",
	"summary": "Admin has been used",
	"sections": [{
		"activityTitle": "JAMF LAPS Password Requested",
		"activityImage": "https://i.imgur.com/W5PzhBr.png",
		"facts": [{
			"name": "Device Name:",
			"value": "'"$name1"'"
		}, {
			"name": "Requested by:",
			"value": "'"$CURRENT_USER"' on '"$DEVICE"'"
		}, {
			"name": "Reason",
			"value": "'"$reason"'"
		}],
		"markdown": true
	}],
	"potentialAction": [{
		"@type": "OpenUri",
		"name": "Challenge Request",
		"targets": [{
			"os": "default",
			"uri":
			"'"$SERVICEDESK"'"
		}]
	}]
}'
				
				# Send the JSON payload using curl
				curl -s -X POST -H "Content-Type: application/json" -d "$jsonPayload" "$7"
			fi