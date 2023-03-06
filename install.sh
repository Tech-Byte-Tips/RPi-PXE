#!/bin/bash
# Script Name: RPI-PXE - Installer
# Author: PREngineer (Jorge Pabón) - pianistapr@hotmail.com
# Publisher: Jorge Pabón
# License: Personal Use (1 device)
###########################################################

# Helper var to show progress
showSpinner(){
  # Grab the process id of the previous command
  pid=$!

  # Characters of the spinner
  spin='-\|/'

  i=0
  # Run until it stops
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .1
  done
}

# Color definition variables
YELLOW='\e[33;3m'
RED='\e[91m'
BLACK='\033[0m'
CYAN='\e[96m'
GREEN='\e[92m'

SCRIPTPATH=$(pwd)

# Display the Title Information
echo 
echo -e $RED
echo -e "╔══════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo -e "║──────────────────────────────────────────────────────────────────────────────────────────────────────────────║"
echo -e "║─████████████████───██████████████─██████████────────────────██████████████─████████──████████─██████████████─║"
echo -e "║─██░░░░░░░░░░░░██───██░░░░░░░░░░██─██░░░░░░██────────────────██░░░░░░░░░░██─██░░░░██──██░░░░██─██░░░░░░░░░░██─║"
echo -e "║─██░░████████░░██───██░░██████░░██─████░░████────────────────██░░██████░░██─████░░██──██░░████─██░░██████████─║"
echo -e "║─██░░██────██░░██───██░░██──██░░██───██░░██──────────────────██░░██──██░░██───██░░░░██░░░░██───██░░██─────────║"
echo -e "║─██░░████████░░██───██░░██████░░██───██░░██───██████████████─██░░██████░░██───████░░░░░░████───██░░██████████─║"
echo -e "║─██░░░░░░░░░░░░██───██░░░░░░░░░░██───██░░██───██░░░░░░░░░░██─██░░░░░░░░░░██─────██░░░░░░██─────██░░░░░░░░░░██─║"
echo -e "║─██░░██████░░████───██░░██████████───██░░██───██████████████─██░░██████████───████░░░░░░████───██░░██████████─║"
echo -e "║─██░░██──██░░██─────██░░██───────────██░░██──────────────────██░░██───────────██░░░░██░░░░██───██░░██─────────║"
echo -e "║─██░░██──██░░██████─██░░██─────────████░░████────────────────██░░██─────────████░░██──██░░████─██░░██████████─║"
echo -e "║─██░░██──██░░░░░░██─██░░██─────────██░░░░░░██────────────────██░░██─────────██░░░░██──██░░░░██─██░░░░░░░░░░██─║"
echo -e "║─██████──██████████─██████─────────██████████────────────────██████─────────████████──████████─██████████████─║"
echo -e "║────────────────────────────────────────────────────────────────────────────────────────────────────Installer─║"
echo -e "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
echo -e "                                                                      Brought to you by Jorge Pabon (PREngineer)"
echo
echo -e $BLACK

# Validate it's run as root
if [ $(id -u) -ne 0 ]; then
  echo -e $RED"You must run RPI-PXE-Server as root user, like this: sudo $0"
  exit 1
fi

echo
echo $BLACK"Updating packages ..."
echo

# Run an update
apt-get update -y > /dev/null
showSpinner
if [ $? -ne 0 ]; then
  echo -e $RED"[!] An error occurred while updating the package indexes!"
  exit 1
fi

echo
echo $BLACK"Upgrading packages and system ..."
echo

# Run an upgrade
apt-get upgrade -y > /dev/null
showSpinner
apt-get dist-upgrade -y > /dev/null
showSpinner
if [ $? -ne 0 ]; then
  echo -e $RED"[!] An error occurred while upgrading the packages and system!"
  exit 1
fi

echo
echo $BLACK"Installing NFS Kernel Server ..."
echo

# Install NFS
#sudo apt install nfs-kernel-server -y > /dev/null
showSpinner
if [ $? -ne 0 ]; then
  echo -e $RED"[!] An error occurred while installing the NFS Kernel Server!"
  exit 1
fi

echo
echo $BLACK"Installing DNSMasq ..."
echo

# Install NFS
#sudo apt install dnsmasq -y > /dev/null
showSpinner
if [ $? -ne 0 ]; then
  echo -e $RED"[!] An error occurred while installing the NFS Kernel Server!"
  exit 1
fi

echo -e $BLACK'Creating file structure to serve ...'



echo "Done!"

exit 0