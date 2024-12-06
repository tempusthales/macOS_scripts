#! /bin/zsh
# Author: Garrett Thorn
# Contributor: Tempus Thales
# pokemon API function w/swiftDialog

# Pre-flight Check: Client-side Logging
##############################################
scriptLog="/var/log/whatever/pokemonapi.log"

# Check if the log directory exists, if not create it
if [[ ! -d "$(dirname "${scriptLog}")" ]]; then
	mkdir -p "$(dirname "${scriptLog}")"
fi
if [[ ! -f "${scriptLog}" ]]; then
	touch "${scriptLog}"
fi

# Log update function
function updateScriptLog() {
	# echo -e "$(date +%Y-%m-%d\ %H:%M:%S) - ${1}" | tee -a "${scriptLog}"
	printf "%s - %s\n" "$(date +%Y-%m-%d\ %H:%M:%S)" "${1}" >> "${scriptLog}"
}

# Pre-flight Check: Logging Preamble
##############################################

# updateScriptLog "\n\n###\n# Name of your App (${scriptVersion})\n# Join https://macadmins.org"
# updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

updateScriptLog "###"
updateScriptLog "# Name of your App (${scriptVersion})"
updateScriptLog "# Join https://macadmins.org"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# Pre-flight Check: swiftDialog check
##############################################

function dialogCheck(){
	# Get the URL of the latest PKG From the Dialog GitHub repo
	dialogURL=$(curl --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
	# Expected Team ID of the downloaded PKG
	expectedDialogTeamID="PWA5E9TQ59"
	
	# Check for Dialog and install if not found
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		updateScriptLog "Dialog not found. Installing..."
		# Create temporary working directory
		workDirectory=$( /usr/bin/basename "$0" )
		tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
		# Download the installer package
		updateScriptLog "Downloading Dialog.pkg..."
		/usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
		# Verify the download
		teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
		# Install the package if Team ID validates
		if [ "$expectedDialogTeamID" = "$teamID" ] || [ "$expectedDialogTeamID" = "" ]; then
			updateScriptLog "Installing Dialog.pkg..."
			/usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
		else
			updateScriptLog "Dialog Team ID verification failed."
			exit 1
		fi
		# Remove the temporary working directory when done
		/bin/rm -Rf "$tempDirectory"
		updateScriptLog "Dialog installation complete."
	else
		updateScriptLog "Dialog found. Proceeding..."
	fi
}

# Script Begins
##############################################

obtainPokemonInformation() {
    local pokemonId="$1"
    local result

    updateScriptLog "Fetching data for Pokemon ID: $pokemonId"
    result=$(curl --location "https://pokeapi.co/api/v2/pokemon/$pokemonId" 2>/dev/null)

    if [[ -z "$result" ]]; then
        updateScriptLog "Failed to retrieve data for Pokemon ID: $pokemonId"
        exit 1
    else
        updateScriptLog "Data successfully retrieved for Pokemon ID: $pokemonId"
    fi

    echo $result
}

# Create a random number 1-1025; the API has 1025 different Pokémon to choose from
randomNumber=$((1 + RANDOM % 1025))
updateScriptLog "Generated random Pokemon ID: $randomNumber"

# Send the random number to our ObtainPokemonInformation function, which returns the results from the API
pokemonResult=$(obtainPokemonInformation "$randomNumber")

# From the returned JSON response, use jq to pull out the name of the Pokémon, how many types it has, and a link to the sprite image
pokemonName=$(echo $pokemonResult | jq -r '.name' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
pokemonTypeLength=$(echo $pokemonResult | jq -r '.types | length')
pokemonSprite=$(echo $pokemonResult | jq -r '.sprites.front_default')

updateScriptLog "Parsed Pokémon data - Name: $pokemonName, Type Count: $pokemonTypeLength, Sprite: $pokemonSprite"

# If the Pokémon only has one type
if [ "$pokemonTypeLength" = "1" ]; then
    pokemonType1=$(echo $pokemonResult | jq -r '.types.[0].type.name' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    pokemonTypeFinal="$pokemonType1"
    updateScriptLog "Pokemon Type: $pokemonTypeFinal"
# If the Pokémon has two types
elif [ "$pokemonTypeLength" = "2" ]; then
    pokemonType1=$(echo $pokemonResult | jq -r '.types.[0].type.name' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    pokemonType2=$(echo $pokemonResult | jq -r '.types.[1].type.name' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    pokemonTypeFinal="$pokemonType1 and $pokemonType2"
    updateScriptLog "Pokemon Types: $pokemonTypeFinal"
fi

dialogCheck

# Start the dialog window with all our variables we used above
dialog=$(/usr/local/bin/dialog \
    --title "My Super Cool App" \
    --titlefont size=22 \
    --message "Join MacAdmins Slack! \n\nTo join MacAdmin's Slack go to https://macadmins.org and invite yourself to the slack. It's free! \n\nClick the **?** on the bottom right corner of the ui." \
    --messagefont size=16 \
    --ontop \
    --moveable \
    --centericon \
    --helpmessage "OMG you found the secret within the project management script.\n\nYour random Pokémon is:\n\n$pokemonName\n\nType: $pokemonTypeFinal" \
    --helpimage "$pokemonSprite" \
    --icon "https://i.imgur.com/ooWHhHa.png"
    )

updateScriptLog "Dialog displayed with Pokémon details. Exiting script."

exit 0