#! /bin/bash

wget -q -O ./Installer https://github.com/Moonlight-Panel/Installer/releases/latest/download/Installer_$(uname -m)
chmod +x Installer
clear
sudo ./Installer
