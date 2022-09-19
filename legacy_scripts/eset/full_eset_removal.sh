#!/bin/sh

# This script will begin by removing the ESET Remote Administrator Agent
# then continue by executing the Remove ESET Endpoint Antivirus client.
# A cleanup process will remove the remaining links from the finder and other
# parts of the deployment.

## Stop and unload service
echo "Stoping ESET Remote Administrator Agent... "
sudo /bin/launchctl remove com.eset.remoteadministrator.agent

## Remove launchdaemons
echo "Removing LaunchDaemon... "
sudo /bin/rm "/Library/LaunchDaemons/com.eset.remoteadministrator.agent_daemon.plist"

## Call forget in pkgutil
echo "Removing from pkgutil... "
sudo /usr/sbin/pkgutil --forget com.eset.remoteadministrator.agent

## Remove ESET Remote Administrator Agent data
echo "Removing application data directory... "
sudo /bin/rm -rf "/Library/Application Support/com.eset.remoteadministrator.agent"

# !!! This has to be the last removal, because this script is located in this directory and sudo needs existing working directory on some versions of OS X, otherwise it will fail !!!
## Remove ESET Remote Administrator Agent
echo "Removing application directory... "
sudo /bin/rm -rf "/Applications/ESET Remote Administrator Agent.app"

# Remove ESET Endpoint Antivirus

echo "ESET Endpoint Antivirus Version 6.5.432.1 Uninstall Script"
echo "This script will uninstall ESET Endpoint Antivirus 6.5.432.1."

if [ $EUID -ne 0 ]; then
	echo " "
	echo "Warning: Uninstallation of ESET Endpoint Antivirus 6.5.432.1 could be made only by user with root privileges!"
	echo " "
	exit 2
fi
echo " "

dr="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# !!! lines above are deleted during remote_uninstallation script creation, so do not insert new lines without makepkg.perl modification !!!
lg=/tmp/esets_uninstall.log
s="Starting uninstallation procedure using '$0'";
echo $s > $lg; echo $s

if [ -d "$dr" ]; then 
	for i in 1 2 3 4 5 6 7
	do
		s="Executing uninstaller tool $i..."
		echo "" >> $lg; echo $s >> $lg; echo $s
		"$dr/../Helpers/ut$i" 2> /dev/null 1>&2
		rc=$?
		pd=$!
		if [ "$rc" -ne 0 ]; then
			s="ERROR: uninstallation step $i failed! Cannot execute tool '$dr/../Helpers/ut$i'"
			echo $s >> $lg; echo $s
			exit $rc;
		fi
	done
	s="Uninstallation finished successfully!"
else
	s="Product is not installed or installation is corrupted !"
fi
echo "" >> $lg; echo ""
echo $s >> $lg; echo $s

