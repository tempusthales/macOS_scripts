#!/bin/bash

# Author: Tempus Thales
# Contributors: BigMacAdmin@MacAdmins, adamcodega@MacAdmins
# Date: 08/06/2024
# Version: 2024.08.06-1.0
# Description: Script to run promptForRestart.sh

# Variables
plistPath="/Library/LaunchDaemons/com.company.de.restartprompt.plist"
promptScriptPath="/usr/local/bin/promptForRestart.sh"
stdoutLog="/var/log/rebootprompt_stdout.log"
stderrLog="/var/log/rebootprompt_stderr.log"

# Function to log actions
function updateScriptLog() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - ${1}"
}

updateScriptLog "Starting LaunchDaemon creation process..."

# Ensure the /usr/local/bin/promptForreboot.sh script exists and is executable
if [[ -f "$promptScriptPath" ]]; then
  updateScriptLog "Found $promptScriptPath."
  chmod +x "$promptScriptPath"
  updateScriptLog "Ensured $promptScriptPath is executable."
else
  updateScriptLog "ERROR: $promptScriptPath not found. Please ensure the script exists."
  exit 1
fi

# Ensure log files exist and have the correct permissions
if [[ ! -f "$stdoutLog" ]]; then
  touch "$stdoutLog"
  updateScriptLog "Created $stdoutLog."
fi
if [[ ! -f "$stderrLog" ]]; then
  touch "$stderrLog"
  updateScriptLog "Created $stderrLog."
fi

chmod 644 "$stdoutLog" "$stderrLog"
chown root:wheel "$stdoutLog" "$stderrLog"
updateScriptLog "Set permissions for log files."

# Unload existing LaunchDaemon if it exists
if [[ -f "$plistPath" ]]; then
  updateScriptLog "Unloading existing LaunchDaemon."
  launchctl unload "$plistPath"
fi

# Create the LaunchDaemon to run the main reboot prompt script asynchronously
cat << EOF > "$plistPath"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.company.restartprompt</string>
    <key>ProgramArguments</key>
    <array>
      <string>$promptScriptPath</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$stdoutLog</string>
    <key>StandardErrorPath</key>
    <string>$stderrLog</string>
  </dict>
</plist>
EOF

updateScriptLog "Created $plistPath."

# Ensure correct permissions for the LaunchDaemon
chmod 644 "$plistPath"
chown root:wheel "$plistPath"
updateScriptLog "Set permissions and ownership for $plistPath."

# Validate the .plist file syntax
updateScriptLog "Validating $plistPath..."
if ! plutil "$plistPath"; then
  updateScriptLog "ERROR: $plistPath is not valid. Please check the plist syntax."
  exit 1
fi

# Use `bootstrap` for richer errors and proper system integration in JAMF
updateScriptLog "Loading the new LaunchDaemon using bootstrap."
if sudo launchctl bootstrap system "$plistPath"; then
  updateScriptLog "LaunchDaemon loaded successfully."
else
  updateScriptLog "ERROR: Failed to load the LaunchDaemon."
  exit 1
fi

updateScriptLog "LaunchDaemon creation and loading process completed."

# Exit the JAMF policy script, allowing JAMF to continue with other tasks
exit 0