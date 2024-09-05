#!/bin/bash

# Author: Tempus Thales
# Date: 05/20/2024
# Version: 2.0
# Description: Hostname Automation

####################################################################################################
# Define Logging Function
####################################################################################################
LOG_FILE="/var/log/mac_rename_debug.log"

# Function to update script log
updateScriptLog() {
    local message=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE" >/dev/null
}

# Ensure the log file directory exists and create the log file
mkdir -p "$(dirname "$LOG_FILE")" || exit 2
touch "$LOG_FILE" || { echo "Failed to create log file. Exiting."; exit 2; }

####################################################################################################
# Function to get device type
####################################################################################################
get_device_type() {
    updateScriptLog "Determining device type..."
    if /usr/sbin/ioreg -c AppleSmartBattery -r | awk '/BatteryInstalled/ {print $3}' | grep -q "Yes"; then
        updateScriptLog "Device type: Laptop"
        echo "L"  # Laptop
    else
        updateScriptLog "Device type: Desktop"
        echo "D"  # Desktop
    fi
}

# Function to get identifier (center 5 digits of the serial number)
####################################################################################################
get_identifier() {
    updateScriptLog "Retrieving identifier..."
    local identifier
    identifier=$(system_profiler SPHardwareDataType | awk '/Serial Number/ {print $NF}')
    
    local numDigits=5
    local offset=$(( (${#identifier} - numDigits) / 2 ))
    local digits=${identifier:${offset}:${numDigits}}
    
    if [[ ${#digits} -ne ${numDigits} ]]; then
        updateScriptLog "Something went wrong parsing the identifier, $identifier, $digits"
        echo "Something went wrong parsing the identifier, $identifier, $digits"
        exit 2
    fi
    
    updateScriptLog "Identifier retrieved: $digits"
    echo "$digits"
}

# Function to get location based on system timezone
####################################################################################################
get_location_code() {
    updateScriptLog "Determining location code based on timezone..."
    local timezone
    timezone=$(readlink /etc/localtime | sed 's~.*info/~~')
    
    updateScriptLog "Timezone: $timezone"
    
    local country_code
    country_code=$(grep "$timezone" /usr/share/zoneinfo/zone.tab | awk '{print $1}')
    
    if [ -z "$country_code" ]; then
        updateScriptLog "Failed to determine location code. Country code is empty."
        echo "UNKNOWN"
        return 1
    fi
    
    updateScriptLog "Location code determined: $country_code"
    echo "$country_code"
}

# Main rename function
####################################################################################################
rename_device() {
    local device_type
    device_type=$(get_device_type)
    
    local identifier
    identifier=$(get_identifier)
    
    local location_code
    location_code=$(get_location_code)
    
    if [ "$1" = "--get-expected-name" ]; then
        echo "${device_type}${location_code}${identifier}"
        return
    fi
    
    updateScriptLog "Starting device renaming process."
    
    if [ "$device_type" == "UNKNOWN" ]; then
        updateScriptLog "Failed to determine device type."
        echo "Failed to determine device type."
        exit 1
    fi
    updateScriptLog "Device type determined: $device_type"
    
    if [ -z "$identifier" ]; then
        updateScriptLog "Failed to retrieve identifier."
        echo "Failed to retrieve identifier."
        exit 2
    fi
    updateScriptLog "Identifier retrieved: $identifier"
    
    if [ "$location_code" == "UNKNOWN" ]; then
        updateScriptLog "Location code is unknown."
        echo "Location code is unknown."
        exit 4
    fi
    updateScriptLog "Location code determined: $location_code"
    
    # Construct new name based on device type, location, and identifier
    local new_name="${device_type}${location_code}${identifier}"
    local hname
    hname=$(tr -d "[:blank:]'&()*%$\"\\\/~?!<>[]{}=+:;,.|^#@" <<< "${new_name}")
    updateScriptLog "Constructed new device name: $new_name"
    
    # Set new computer name
    updateScriptLog "Setting new computer name..."
    if scutil --set ComputerName "${new_name}"; then
        updateScriptLog "New computer name set successfully: $new_name"
    else
        updateScriptLog "Failed to set new computer name: $new_name"
        exit 5
    fi
    
    # Set new local hostname
    updateScriptLog "Setting new local hostname..."
    if scutil --set LocalHostName "${hname}"; then
        updateScriptLog "New local hostname set successfully: $hname"
    else
        updateScriptLog "Failed to set new local hostname: $hname"
        exit 6
    fi
    
    # Set new hostname
    updateScriptLog "Setting new hostname..."
    if scutil --set HostName "${hname}"; then
        updateScriptLog "New hostname set successfully: $hname"
    else
        updateScriptLog "Failed to set new hostname: $hname"
        exit 7
    fi
}

####################################################################################################
# Function to check current computer name and proceed with renaming if necessary
####################################################################################################
check_and_rename_computer() {
    updateScriptLog "Checking computer name..."
    local current_name
    current_name=$(scutil --get ComputerName)

    # Debug log current name
    updateScriptLog "Current computer name retrieved: $current_name"

    # Define the expected format regex (example: "LDUS12345")
    local expected_format="^[LD][A-Z]{2}[A-Z0-9]{5}$"

    local expected_name
    expected_name=$(rename_device --get-expected-name)

    if [[ $current_name =~ $expected_format ]] && [ "$current_name" = "$expected_name" ]; then
        updateScriptLog "Computer name is already in the correct format: $current_name"
        echo "Computer name is already in the correct format: $current_name"
        exit 0
    else
        updateScriptLog "Computer name is not in the correct format: $current_name"
        echo "Computer name is not in the correct format: $current_name"
        rename_device
        updateScriptLog "Computer name has been updated to correct format: $current_name"
        echo "Computer name has been set to correct format: $expected_name"
    fi
}

# Check and rename the computer if necessary
check_and_rename_computer