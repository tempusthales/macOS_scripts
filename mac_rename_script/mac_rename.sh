#!/bin/bash

## Script for renaming your macOS Computer on the ComputerName and Hostname.
## If the chassis is a macbook or macbook pro it will add prefix ML-
## If the chassis is a desktop or workstation it will add the prefix MW-
## If the chasses is a Server (only works on Xserve's) it will add the prefix S-
##
## The full computer name will be prefix-serial.tld for example: ML-1234567890.your.domain.com or MW-0987654321.your.domain.com

#define variables
laptop="ML-"
workstation="MW-"
server="S-"
tld="your.domain.com"

# grabbing mac model name...
model=$(ioreg -l | grep "product-name" | cut -d ""="" -f 2 | sed -e s/[^[:alnum:]]//g | sed s/[0-9]//g) 

#and it's serial number...
serial=$(ioreg -l | grep "IOPlaLormSerialNumber" | cut -d ""="" -f 2 | sed -e s/[^[:alnum:]]//g) 

# renaming based on model ie. prefix-computerserial.tld
case "$model" in
                "Xserve" )
                /usr/sbin/scutil --set ComputerName "$server$serial" /usr/sbin/scutil --set LocalHostName "$server$serial" /usr/sbin/scutil --set HostName "${server}${serial}.${tld}"
                echo "$model"
                echo "$server$serial"
                echo "${server}${serial}.${tld}"
                ;;
                "MacBookPro" )
                /usr/sbin/scutil --set ComputerName "$laptop$serial" /usr/sbin/scutil --set LocalHostName "$laptop$serial" /usr/sbin/scutil --set HostName "${laptop}${serial}.${tld}"
                echo "$model"
                echo "$laptop$serial"
                echo "${laptop}${serial}.${tld}"
                ;;
                "MacBookAir" )
                /usr/sbin/scutil --set ComputerName "$laptop$serial" /usr/sbin/scutil --set LocalHostName "$laptop$serial" /usr/sbin/scutil --set HostName "${laptop}${serial}.${tld}"
                echo "$model"
                echo "$laptop$serial"
                echo "${laptop}${serial}.${tld}"
                ;;
                "MacPro" )
                /usr/sbin/scutil --set ComputerName "$workstation$serial" /usr/sbin/scutil --set LocalHostName "$workstation$serial" /usr/sbin/scutil --set HostName "${workstation}${serial}.${tld}" echo “$model"
                echo "$workstation$serial"
                echo "${workstation}${serial}.${tld}"
                ;;
                "iMac" )
                /usr/sbin/scutil --set ComputerName "$workstation$serial" /usr/sbin/scutil --set LocalHostName "$workstation$serial" /usr/sbin/scutil --set HostName "${workstation}${serial}.${tld}" echo "$model"
                echo “$workstation$serial"
                echo "${workstation}${serial}.${tld}"
                ;;
                "Macmini" )
                /usr/sbin/scutil --set ComputerName "$server$serial" /usr/sbin/scutil --set LocalHostName "$server$serial" /usr/sbin/scutil --set HostName "${server}${serial}.${tld}"
                echo "$model"
                echo "$server$serial"
                echo "${server}${serial}.${tld}"
                ;;
                *)
                echo "Computer model not found."
                exit 0
                ;;
esac
