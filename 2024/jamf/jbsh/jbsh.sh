#!/bin/zsh --no-rcs
# shellcheck shell=bash

# Author: Tempus Thales
# Date: 06/08/2024
# Version: 2024.06.08-0.0.1
# Description: Renew Management Framework via Serial Number.

#########################################################################################################
# Authentication method is using Bearer Token
#########################################################################################################

# server connection information
URL=https://yourjss.jamfcloud.com

# Enter a local Jamf Pro user here
username=${4:-"username"}
password=${5:-"password"}

# Define variables
title="Jamf Binary Self-Heal"
message="Please enter macOS device Serial Number."
# icon="SF=laptopcomputer.and.arrow.down"
icon="https://i.imgur.com/CmyJTnq.png"
scriptVersion="v 0.1"
dialogCommandFile="/tmp/dialog_command_file"

# Construct the dialogTool command using an array
dialogTool=(
	--title "$title"
	--titlefont "colour=#00A4C7,weight=light,size=25"
	--message "$message"
	--messagefont "size=16"
	--alignment "left"
	--messagealignment "left"
	--infotext "$scriptVersion"
	--icon "$icon"
	--iconsize '120'
	--button1text "Ok"
	--button2text "Quit"
	--button2
	--moveable
	--ontop
	--width '550'
	--height '200'
	--commandfile "$dialogCommandFile"
)

# Show the dialog and capture the output
dialogOutput=$(/usr/local/bin/dialog "${dialogTool[@]}" --textfield "Serial Number",required)

# Extract the serial number from the dialog output
selectedSerialNumber=$(echo "${dialogOutput}" | grep 'Serial Number :' | awk '{print $NF}')

# Check if selectedSerialNumber is empty
if [ -z "$selectedSerialNumber" ]; then
    echo "No serial number provided"
    exit 1
fi

# Use the selected serial number
echo "Selected Serial Number: $selectedSerialNumber"

# Processing the serial number
processedSerialNumber="${selectedSerialNumber// /}"
echo "Processed Serial Number: $processedSerialNumber"

# created base64-encoded credentials
encodedCredentials=$( printf '%s:%s' "$username" "$password" | /usr/bin/iconv -t ISO-8859-1 | /usr/bin/base64 -i - )

# generate an auth token
authToken=$( /usr/bin/curl "$URL/api/v1/auth/token" \
--silent \
--request POST \
--header "Authorization: Basic $encodedCredentials" )

# Check if authToken contains "token"
if [[ "$authToken" != *"token"* ]]; then
	echo "Failed to obtain auth token"
	exit 1
fi

# parse authToken for token, omit expiration
token=$( /usr/bin/awk -F \" '/token/{ print $4 }' <<< "$authToken" | /usr/bin/xargs )

if [ -z "$token" ]; then
	echo "Failed to parse auth token"
	exit 1
fi

# determine Jamf Pro device id
ID=$(curl -s -H "Accept: application/xml" -H "Authorization: Bearer ${token}" "${URL}/JSSResource/computers/serialnumber/${processedSerialNumber}" | xmllint --xpath '/computer/general/id/text()' - 2>/dev/null)

if [ -z "$ID" ]; then
	echo "Failed to obtain device ID for serial number $processedSerialNumber"
	exit 1
fi

echo "The JSS ID of this computer is $ID"

#Run CURL command that reinstalls management framework
response=$(curl --request POST \
--url "$URL/api/v1/jamf-management-framework/redeploy/$ID" \
--header 'Accept: application/json' \
--header "Authorization: Bearer $token" \
--write-out "HTTPSTATUS:%{http_code}" \
--silent)

# Extract the body and status
http_body="${response%HTTPSTATUS:*}"
http_status="${response##*HTTPSTATUS:}"

echo "HTTP Body: $http_body"
echo "HTTP Status: $http_status"

# Check the status code
if [ "$http_status" -ne 200 ] && [ "$http_status" -ne 202 ]; then
	echo "Error: API call failed with status $http_status"
	exit 1
fi

# expire the auth token
/usr/bin/curl "$URL/uapi/auth/invalidateToken" \
--silent \
--request POST \
--header "Authorization: Bearer $token"

exit 0