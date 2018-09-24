#!/bin/bash

# Tool for checking if there is ethernet, if there is, then it turns WiFi OFF 
# Change IP Ranges according to your environment

# Set variables
  WIFI_PORT=$(networksetup -listallhardwareports | grep -A 1 Wi-Fi | grep Device | awk '{print $2}') 
  ASSIGNED_IP_RANGE="^xx.xx.xx|^xx.xx.xx|^xx.xx|^xx.xx" # !!! Change these ranges to your environment !!!

# If WIFI is disabled (ie. doesn't have an assigned IP), then no need to continue; EXIT!
  WIFI_IP=$(ifconfig ${WIFI_PORT} 2>/dev/null | grep 'inet ' | awk '{print $2}')
  [ "${WIFI_IP}" ] || exit

# Gather list of network ports, minus active WIFI port 
  PORT_LIST=$(networksetup -listallhardwareports | grep Device: | awk '{print $2}' | sed s/${WIFI_PORT}//g)

# If any hardwire port has an IP in the ASSIGNED_IP_RANGE, then disable Wifi, and EXIT!
  for PORT in ${PORT_LIST}; do
    IP=$(ifconfig ${PORT} 2>/dev/null | grep 'inet ' | awk '{print $2}')
    if [ "$(echo ${IP} | egrep $ASSIGNED_IP_RANGE)" ]; then
      DATE_STAMP=$(date "+%b %d %H:%M:%S")
      networksetup -setairportpower ${WIFI_PORT} off
      if [ $? -eq 0 ]; then
        echo "${DATE_STAMP} [info] ${HOSTNAME} - Wifi port disabled: ${WIFI_PORT}, IP: ${WIFI_IP}"
      else
        echo "${DATE_STAMP} [error] ${HOSTNAME} - Wifi port could not be disabled: ${WIFI_PORT}, IP: ${WIFI_IP}"
      fi
    fi
  done
