#!/bin/bash

# Determine working directory

install_dir=`dirname $0`

# Install unlicensed Office 2016

/usr/sbin/installer -dumplog -verbose -pkg $install_dir/"Microsoft_Office_16.20.18120801_Installer.pkg" -target "$3"

# Install Office 2016 Volume License Serializer

/usr/sbin/installer -dumplog -verbose -pkg $install_dir/"Microsoft_Office_2019_VL_Serializer.pkg" -target "$3"

exit 0