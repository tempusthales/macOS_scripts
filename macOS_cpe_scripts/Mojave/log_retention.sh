#!/bin/bash
####################################################################################
# Name:                         log_retention.sh
# Author:                       Tempus Thales
# Purpose:                      Increase log retention timeframes
####################################################################################
# Establish standardized local logging logic
#####################################################################################
log_path="/var/log/company_name"
# if this script does not require local logging uncomment next line and comment out the following line
# log_file=""
log_file="com.company_name.macos.logging.log"

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
# Overwrite new /private/etc/asl.conf
#####################################################################################
logMessage "Writing new /private/etc/asl.conf..."
#create new /private/etc/asl.conf
cat > "/private/etc/asl.conf" << 'EOF'
##
# configuration file for syslogd and aslmanager
##

# aslmanager logs
> /var/log/asl/Logs/aslmanager external style=lcl-b ttl=2

# authpriv messages are root/admin readable
? [= Facility authpriv] access 0 80

# remoteauth critical, alert, and emergency messages are root/admin readable
? [= Facility remoteauth] [<= Level critical] access 0 80

# broadcast emergency messages
? [= Level emergency] broadcast

# save kernel [PID 0] and launchd [PID 1] messages
? [<= PID 1] store

# ignore "internal" facility
? [= Facility internal] ignore

# save everything from emergency to notice
? [<= Level notice] store

# Rules for /var/log/system.log
> system.log mode=0640 format=bsd rotate=utc compress file_max=5M ttl=90
? [= Sender kernel] file system.log
? [<= Level notice] file system.log
? [= Facility auth] [<= Level info] file system.log
? [= Facility authpriv] [<= Level info] file system.log

# Facility com.apple.alf.logging gets saved in appfirewall.log
> appfirewall.log mode=0640 format=bsd rotate=utc compress file_max=5M ttl=90
EOF
logMessage "Setting permissions and ownership for /private/etc/asl.conf"
# set permissions
chmod 600 /private/etc/asl.conf
#set ownership
chown root:wheel /private/etc/asl.conf

logMessage "/private/etc/asl.conf was created/modified on $(ls -alh /private/etc/asl.conf | awk '{print $6,$7,$8}')"
#####################################################################################
# Overwrite new /private/etc/asl/com.apple.install
#####################################################################################
logMessage "Writing new /private/etc/asl/com.apple.install"
# create new /private/etc/asl/com.apple.install
cat > "/private/etc/asl/com.apple.install" << 'EOF'
# install messages get saved only in /var/log/install.log
? [= Facility install] claim only
* file /var/log/install.log mode=0640 format=bsd rotate=utc compress file_max=5M ttl=365
EOF
logMessage "Setting permissions and ownership for /private/etc/asl/com.apple.install"
# set permissions
chmod 600 /private/etc/asl/com.apple.install
#set ownership
chown root:wheel /private/etc/asl/com.apple.install

logMessage "/private/etc/asl/com.apple.install was created/modified on $(ls -alh /private/etc/asl/com.apple.install | awk '{print $6,$7,$8}')"
#####################################################################################
# Overwrite new /private/etc/asl/com.apple.authd
#####################################################################################
logMessage "Writing new /private/etc/asl/com.apple.authd"
# create new /private/etc/asl/com.apple.authd
cat > "/private/etc/asl/com.apple.authd" << 'EOF'
? [= Sender authd] claim only
* file /var/log/authd.log mode=640 format=bsd rotate=utc compress file_max=5M ttl=90
? [<= Level error] file /var/log/system.log
? [<= Level error] store
EOF
logMessage "Setting permissions and ownership for /private/etc/asl/com.apple.authd"
# set permissions
chmod 600 /private/etc/asl/com.apple.authd
#set ownership
chown root:wheel /private/etc/asl/com.apple.authd

logMessage "/private/etc/asl/com.apple.authd was created/modified on $(ls -alh /private/etc/asl/com.apple.authd | awk '{print $6,$7,$8}')"

logMessage "Script complete"
logMessage "Exiting..."
exit 0
