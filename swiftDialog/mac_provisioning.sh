#!/bin/bash
export DIALOG_STATUS_LOCATION="/var/tmp/dialog.log"
export DIALOG="/usr/local/bin/dialog"
export DIALOG_JSON=/Users/Shared/dialog.json
export LOCATION_SERVICE=https://ipwho.is
export POLICY_MANIFEST="/Users/Shared/policy_manifest"
export JAMF_BINARY="/usr/local/bin/jamf"
export DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
export DEP_NOTIFY_DEBUG="/var/tmp/depnotifyDebug.log"
export DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"
export DIALOG_TIMEOUT=6
export TARGET_JSS_INSTANCE="<your.jamfcloud.goes.here>"
export OTHER_JSS_INSTANCE="<your.dev.jamfcloud.goes.here>"
export DEFAULT_USER="defaultuser"
export STAGE=$4
export DAEMON_LOCATION="/Library/LaunchDaemons/com.provision.startup.daemon.plist"
export SCRIPT_ABSOLUTE_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
export POST_RUN_PATH="/Users/Shared/post_run_script.sh"
export FIRST_RUN_FILE="/Users/Shared/firstrun.done"
export NO_SLEEP=true

if [[ "$STAGE" = "prelogin" ]];then 
    sudo rm "${POLICY_MANIFEST}_prelogin.txt"
    sudo rm "${POLICY_MANIFEST}_postlogin.txt"
    sudo rm "${DIALOG_JSON}"
    sudo rm "${FIRST_RUN_FILE}"
    SCRIPT_ABSOLUTE_PATH=$(sed 's/ /\\ /g' <<< "$SCRIPT_ABSOLUTE_PATH")
    echo "Attempting to copy $SCRIPT_ABSOLUTE_PATH to $POST_RUN_PATH" >> $DEP_NOTIFY_DEBUG
    eval cp $SCRIPT_ABSOLUTE_PATH $POST_RUN_PATH
    sudo chmod 777 "${POST_RUN_PATH}"
    
    macOSproductVersion="$( sw_vers -productVersion )"
    macOSbuildVersion="$( sw_vers -buildVersion )"
    serialNumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
    timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
    dialogVersion=$( /usr/local/bin/dialog --version )
    
function dialogCheck(){
  # Get the URL of the latest PKG From the Dialog GitHub repo
  dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
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

######################################################
# Check for swiftDialog and install if not found
dialogCheck

    /usr/bin/env ruby <<-EORUBY
    require 'json'
    require "uri"
    require "net/http"


    CONFIG_MANIFEST = [
        {
            "status"=>"success",
            "title"=>"Installing Rosetta ...",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns",
            "statustext"=> "Completed",
            "command"=>"install_rosetta",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Attempting to Install Rosetta ...",
            "script_stage"=>"prelogin"
        },
        {
            "status"=>"success",
            "title"=>"Add User",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns",
            "statustext"=> "Completed",
            "command"=>"${JAMF_BINARY} policy -event create_user",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Attempting create user ...",
            "script_stage"=>"prelogin"
        },
        {
            "status"=>"success",
            "title"=>"Swift Dialog ...",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertNoteIcon.icns",
            "statustext"=> "Completed",
            "command"=>"${JAMF_BINARY} policy -event swiftDialog",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Attempting to Swift Dialog ...",
            "script_stage"=>"prelogin"
        },
        {
            "title"=>"Set Login Message ...",
            "command"=>"sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText 'This Machine will reboot soon, please do not login ...'",
            "region"=>"all",
            "show_in_list"=>false,
            "progresstext"=>"Setting pre-login message ...",
            "script_stage"=>"prelogin",
        },
        {
            "title"=>"Waiting for Login ...",
            "command"=>"wait_for_login" ,
            "region"=>"all",
            "show_in_list"=>false,
            "progresstext"=>"Waiting for login ...",
            "script_stage"=>"prelogin"
        },
        {
            "title"=>"Reset Login Message ...",
            "command"=>"sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText ''" ,
            "region"=>"all",
            "show_in_list"=>false,
            "progresstext"=>"Reset Login Message",
            "script_stage"=>"postlogin"
        },
        {
            "title"=>"Waiting for finder ...",
            "command"=>"wait_for_finder" ,
            "region"=>"all",
            "show_in_list"=>false,
            "progresstext"=>"Waiting for finder ...",
            "script_stage"=>"postlogin"
        },
        {
            "title"=>"Get Current User",
            "command"=>"export CURRENT_USER=`ls -l /dev/console | cut -d " " -f 4`" ,
            "region"=>"all",
            "show_in_list"=>false,
            "progresstext"=>"Getting Current User ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"success",
            "title"=>"DEP Notify ...",
            "icon"=>"/Applications/Utilities/DEPNotify.app/Contents/Resources/AppIcon.icns",
            "statustext"=> "Completed",
            "command"=>"${DIALOG} --jsonfile ${DIALOG_JSON}" ,
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Attempting to Install DEP Notify ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Syncing with JAMF ...",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Everyone.icns",
            "command"=>"${JAMF_BINARY} recon",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Performing JAMF Recon ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Crowdstrike ...",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/LockedIcon.icns",
            "command"=>"${JAMF_BINARY} policy -event crowdstrike",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Installing Crowdstrike ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"DockUtil ...",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarDesktopFolder.icns",
            "command"=>"${JAMF_BINARY} policy -event dockutil",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Installing DockUtil ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Setting Dock",
            "icon"=>"/System/Library/CoreServices/Dock.app/Contents/Resources/Dock.icns",
            "command"=>"${JAMF_BINARY} policy -event dock",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Installing DockUtil ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Setting Desktop Background",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.pro-display-xdr.icns",
            "command"=>"${JAMF_BINARY} policy -event retail-wallpaper",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Setting Desktop Background ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Setting Screensaver",
            "icon"=>"/System/Library/CoreServices/ScreenSaverEngine.app/Contents/Resources/ScreenSaverEngine.icns",
            "command"=>"${JAMF_BINARY} policy -event screensaver_en",
            "region"=>"NA",
            "show_in_list"=>true,
            "progresstext"=>"Setting Screensaver ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Setting bookmarks",
            "icon"=>"/Applications/Safari.app/Contents/Resources/AppIcon.icns",
            "command"=>"${JAMF_BINARY} policy -event bookmarks-cn",
            "region"=>"CN , AP",
            "show_in_list"=>true,
            "progresstext"=>"Setting bookmarks ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Setting bookmarks",
            "icon"=>"/Applications/Safari.app/Contents/Resources/AppIcon.icns",
            "command"=>"${JAMF_BINARY} policy -event bookmarks",
            "region"=>"NA",
            "show_in_list"=>true,
            "progresstext"=>"Setting bookmarks ...",
            "script_stage"=>"postlogin"
        },
        {
            "status"=>"wait",
            "title"=>"Post Config Cleanup",
            "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/Sync.icns",
            "command"=>"post_config_cleanup",
            "region"=>"all",
            "show_in_list"=>true,
            "progresstext"=>"Performing post configuration ...",
            "script_stage"=>"postlogin"
        }
    ]

    BASE_MANIFEST = {
        'title' => "Welcome To Company Name!",
        'titlefont'=>"size=26",
        'message'=>"We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 15 to 30 minutes to complete. \n \n If you need additional software or help, please visit the Self Service app in your Applications folder or on your Dock.", 
        "messagefont"=>"size=13",
        "ontop"=>true,
        "big"=>true,
        "icon"=>"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/com.apple.imac-2021-silver.icns",
        "overlayicon"=>"/opt/company/SS-Logo.png",
        "overlay"=>"/opt/company/1920x1200_Generic-lockscreen.jpg",
        "progress"=>true,
        "progresstext"=>"Initializing Configuration ...",
        "blurscreen"=>true,
        "button1disabled"=>true,
        "hideicon"=> 0,
        "quitoninfo"=> 1,
        "listitem"=>[]
    }

    def return_location_data(url_unencoded)
        url = URI(url_unencoded)
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        
        request = Net::HTTP::Get.new(url)
        response = https.request(request)
        if response.code != "200"
            return "Failed"
        else
            parsed_json = JSON.parse(response.body)
            if parsed_json['continent_code'] == "AS"
                if parsed_json['continent_code'] == "CN"
                    return "CN"
                else
                    return "AP"
                end
            end
            return parsed_json['continent_code']
        end
    end
    def build_prompt()

        region = return_location_data("$LOCATION_SERVICE")
        output_manifest = []
        CONFIG_MANIFEST.each { |x| 
            
            if ( x['region'].include? region or "all" == x['region'] )
                if x['show_in_list'] == true
                    output_manifest.append(x)
                end
                File.open("#{"$POLICY_MANIFEST"}_#{x['script_stage']}.txt","a") do |f|
                    f.write("#{x['title']},#{x['command']},#{x['progresstext']}\n")
                end
            end
        }
        BASE_MANIFEST['listitem']=output_manifest
        # BASE_MANIFEST['infobox']="**Serial Number:** \n $serialNumber \n\n **macOS Version:** \n $macOSproductVersion \n\n **macOS Build:** \n  $macOSbuildVersion \n\n **Started:** \n $timestamp \n\n **Region:** \n #{region} \n\n"
        File.open("$DIALOG_JSON","w") do |f|
            f.write(BASE_MANIFEST.to_json)
        end

    end
    build_prompt()
EORUBY

plist="
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
  <dict>
    <key>Label</key>
    <string>com.startup.daemon</string>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:</string>
    </dict>

    <key>Program</key>
    <string>/bin/bash</string>
    <key>ProgramArguments</key>
    <array>
        <string>bash</string>
        <string>$POST_RUN_PATH</string>
        <string>postlogin</string>
    </array>
    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>$DEP_NOTIFY_LOG</string>
    <key>StandardErrorPath</key>
    <string>$DEP_NOTIFY_LOG</string>
    <key>UserName</key>
    <string>root</string>

  </dict>
</plist>
"
sudo chmod 777 "${POLICY_MANIFEST}_prelogin.txt"
sudo chmod 777 "${POLICY_MANIFEST}_postlogin.txt"
sudo chmod 644 "${DAEMON_LOCATION}"
sudo launchctl unload $DAEMON_LOCATION
sudo rm -f $DAEMON_LOCATION


else
	STAGE="postlogin"
    if [ ! -f "$FIRST_RUN_FILE" ]; then
        echo "$(date "+%a %h %d %H:%M:%S"): First RUN PreReboot" > $FIRST_RUN_FILE
        sudo shutdown -r NOW
        exit 0
    fi
fi
install_rosetta() {
    arch=$(/usr/bin/arch)
    if [[ "$arch" == "arm64" ]]; then
        echo "$(date "+%a %h %d %H:%M:%S"): Apple Silicon Detected - Installing Rosetta"
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        rosettainstalled=$( pgrep oahd 2>&1 >/dev/null ; echo $? )
        until [ "$rosettainstalled" == "0" ]; do
            sleep 3
            rosettainstalled=$( pgrep oahd 2>&1 >/dev/null ; echo $? )
        done
    elif [[ "$arch" == "i386" ]]; then
        echo "$(date "+%a %h %d %H:%M:%S"): Intel Detected - Skipping Rosetta"
        rosettainstalled=0
    else
        echo "Unknown Architecture"
    fi
    (exit $rosettainstalled)
}
set_auto_login() {

    sudo defaults write /Library/Preferences/com.apple.loginwindow.plist autoLoginUser $DEFAULT_USER
    sudo plutil -replace autoLoginUser -string $DEFAULT_USER /Library/Preferences/com.apple.loginwindow.plist
    sudo /usr/libexec/PlistBuddy -c "Set autoLoginUser $DEFAULT_USER" /Library/Preferences/com.apple.loginwindow.plist

}
wait_for_login() {

  SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
  until [ "$SETUP_ASSISTANT_PROCESS" = "" ]; do
    sleep 1
    SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
    echo "$(date "+%a %h %d %H:%M:%S"): Waiting for Setup Assistant to Close ..."
  done
 	echo "$(date "+%a %h %d %H:%M:%S"): Loading Daemon into Launchctl ..."
    sudo echo $plist > $DAEMON_LOCATION
    sudo launchctl load $DAEMON_LOCATION
    sudo chmod 644 "${DAEMON_LOCATION}"
  echo "$(date "+%a %h %d %H:%M:%S"): Rebooting ..."
  sudo shutdown -r NOW
}

wait_for_finder() {
echo "Entered Wait for Finder ..."
    #while true;	do
    #    myUser=`whoami`
    #    dockcheck=`ps -ef | grep [/]System/Library/CoreServices/Dock.app/Contents/MacOS/Dock`
    #    echo "Waiting for file as: ${myUser}"
    #    sudo echo "Waiting for file as: ${myUser}" 
    #    echo "regenerating dockcheck as ${dockcheck}."

     #   if [ ! -z "${dockcheck}" ]; then
     #       echo "Dockcheck is ${dockcheck}, breaking."
     #       break
     #   fi
     #   sleep 1
    #done
  FINDER_PROCESS=$(pgrep -l "Finder")
  until [ "$FINDER_PROCESS" != "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen."
    echo "Waiting for file as: ${myUser}"
    sleep 1
    FINDER_PROCESS=$(pgrep -l "Finder")
  done
echo "Finder Found ..."
}
get_jamf_instance() {
#    export JSS_INSTANCE=$( /usr/libexec/PlistBuddy '/Library/Preferences/com.jamfsoftware.jamf.plist' -c Print:jss_url )
#    if [[ "$JSS_INSTANCE"="$OTHER_JSS_INSTANCE" ]];then
#        export TARGET_JAMF=1
#    elif [[ "$JSS_INSTANCE"="$TARGET_JSS_INSTANCE" ]];then
#        echo "RETAIL"
        export TARGET_JAMF=0
#    fi
}

update_perform_action() {
    export title=$1
    export command=$2
    export counter=$3
    export progresstext=$4
    export total=$5
    

    
    current_step=$((100/$total*($counter-1)))
    echo "$(date "+%a %h %d %H:%M:%S"): Current Step: $title "
    update_dialog "progress: $current_step"
    sleep 0.1
    update_dialog "progresstext: $progresstext"
    update_dialog "listitem: title: $title, statustext: Installing,status: wait"
    if [[ "$command" = "${DIALOG} --jsonfile ${DIALOG_JSON}" ]];then
        sudo -u "$CURRENT_USER" $command & sleep 0.1
        output_return=0
        update_log $DEP_NOTIFY_DEBUG "Launching Dialog Prompt ..."
        update_dialog "--infobox \"**macOS Version:**  \n$macOSproductVersion  \n\n  **macOS Build:**  \n$macOSbuildVersion  \n\n **Serial Number:**  \n$serialNumber  \n\n **Start Time:**  \n$timestamp  \n\n\" "
    elif [[ "$command" = "wait_for_finder" ]];then
        wait_for_finder
    elif [[ "$command" = "wait_for_login" ]];then
        wait_for_login
    elif [[ "$title" = "Get Current User" ]];then
        export CURRENT_USER=`ls -l /dev/console | cut -d " " -f 4`
        update_log $DEP_NOTIFY_DEBUG "Getting Current User: $CURRENT_USER ..."
    else
        if [ "$TARGET_JAMF" = "1" ];then
            update_log $DEP_NOTIFY_DEBUG "Testing Mode: $title, $command , being simulated with 3 second sleep ..." 
            sleep 1
            output_return=0
        else
            $command;output_return=$?;
        fi
    fi
    if [ "$output_return" = "0" ]; then
        update_dialog "listitem: title: $title, statustext: Completed,status: success"
    else
        update_dialog "listitem: title: $title, statustext: Failed,status: fail"
    fi
}

update_dialog() {
    echo $1>> $DIALOG_STATUS_LOCATION
    update_log $DEP_NOTIFY_DEBUG $1 
}
update_log() {
    echo "$(date "+%a %h %d %H:%M:%S"): $2 ">> "$1"

}
post_config_cleanup() {
    sudo /usr/bin/defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 1
    sudo /usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true
    su $CURRENT_USER -c 'open -a Safari'
    sleep 5
    pkill Safari
    su $CURRENT_USER -c '/usr/bin/defaults write /Users/<username>/Library/Preferences/com.apple.dock.plist wvous-bl-corner -int 5'
    su $CURRENT_USER -c '/usr/bin/defaults write /Users/<username>/Library/Preferences/com.apple.dock.plist wvous-bl-modifier -int 0'
    su $CURRENT_USER -c 'killall Dock'
}
main() {
    get_jamf_instance
    counter=1
    SELECTED_MANIFEST="${POLICY_MANIFEST}_${STAGE}.txt"
    total=$( wc -l $SELECTED_MANIFEST | awk '{ print $1 }')    
    increment_amount=9
    while read POLICY; do
        update_perform_action "$(echo "$POLICY" | cut -d ',' -f1)" "$(echo "$POLICY" | cut -d ',' -f2)" "$counter" "$(echo "$POLICY" | cut -d ',' -f3)" "$total"
        counter=$(($counter+1))
    done <$SELECTED_MANIFEST
    if [[ "$STAGE" = "postlogin" ]];then
        update_dialog "progress: 100"
        until [ "$DIALOG_TIMEOUT" = "0" ];do
            update_dialog "progresstext: Configuration Completed ... Closing in $DIALOG_TIMEOUT"
            sleep 1
            DIALOG_TIMEOUT=$(($DIALOG_TIMEOUT-1))
        done
        update_dialog "quit:"
        sleep 0.1
        if [ "$TARGET_JAMF" = "0" ];then
            sudo shutdown -r +1 
        fi
        #sleep 10 && sudo rm -f $DAEMON_LOCATION &
        #sudo launchctl unload $DAEMON_LOCATION
        sudo rm -f $DAEMON_LOCATION
        sudo launchctl unload com.provision.startup.daemon
    fi
}

    
main
