#!/bin/bash
# Script Name: RPI-PXE - Installer
# Author: PREngineer (Jorge Pabon) - pianistapr@hotmail.com
# Publisher: Jorge Pabon
# License: Personal Use (1 device)
###########################################################

################### VARIABLES ###################

# Location where we are executing
SCRIPTPATH=$(pwd)

# Color definition variables
BLACK='\e[0m'
CYAN='\e[36m'
YELLOW='\e[33m'
RED='\e[31m'
GREEN='\e[32m'




################### FUNCTIONS ###################

# Helper function to show progress
showSpinner(){
  # Grab the process id of the previous command
  pid=$!

  # Characters of the spinner
  spin='-\|/'

  i=0

  # Run until it stops
  while [ -d /proc/$pid ]
  do
    i=$(( (i+1) %4 ))
    printf "\r${spin:$i:1}"
    sleep .2
  done
}

showHeader(){
  # Clean the screen
  clear

  # Display the Title Information
  echo
  echo -e $CYAN
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
  echo -e
}



################### EXECUTION ###################


showHeader

# Validate it's run as root
if [ $(id -u) -ne 0 ]; then
  echo -e $RED "[!] Error: You must run RPI-PXE-Server as root user, like this: sudo $SCRIPTPATH/install.sh or sudo $0" $BLACK
  echo
  exit 1
fi



echo
echo -e $CYAN "Updating list of packages ..." $BLACK
echo

# Run an update
#apt-get update -y > /dev/null & showSpinner
echo
if [ $? -ne 0 ]; then
  echo -e $RED "[!] An error occurred while updating the package indexes!" $BLACK
  exit 1
fi



echo
echo -e $CYAN "Upgrading packages ..." $BLACK
echo

# Run a package upgrade
#apt-get upgrade -y > /dev/null & showSpinner
echo
if [ $? -ne 0 ]; then
  echo -e $RED "[!] An error occurred while upgrading the packages!" $BLACK
  exit 1
fi



echo
echo -e $CYAN "Upgrading system ..." $BLACK
echo

# Run a system upgrade
#apt-get dist-upgrade -y > /dev/null & showSpinner
echo
if [ $? -ne 0 ]; then
  echo -e $RED "[!] An error occurred while upgrading the system!" $BLACK
  exit 1
fi



echo
echo -e $CYAN "Checking installion of NFS Kernel Server ..." $BLACK
echo

# Check if already installed
NFS_STATUS=$(dpkg-query -W --showformat='${Status}\n' nfs-kernel-server|grep "install ok installed")
if [ "" = "$NFS_STATUS" ]; then
  echo -e $YELLOW "  - NFS Kernel Server is not installed yet. It will be installed now ..." $BLACK
  echo
  # Install NFS
  apt-get install nfs-kernel-server -y > /dev/null & showSpinner
  echo
else
  echo -e $GREEN "  - NFS Kernel Server has already been installed. :)" $BLACK
  echo
fi
# Check for error while running installation
if [ $? -ne 0 ]; then
  echo -e $RED "[!] An error occurred while installing the NFS Kernel Server!" $BLACK
  exit 1
fi



echo
echo -e $CYAN "Installing DNSMasq ..." $BLACK
echo

# Check if already installed
DNSMASQ_STATUS=$(dpkg-query -W --showformat='${Status}\n' dnsmasq|grep "install ok installed")
if [ "" = "$DNSMASQ_STATUS" ]; then
  echo -e $YELLOW "  - DNSMasq is not installed yet. It will be installed now ..." $BLACK
  echo
  # Install DNSMasq
  apt-get install dnsmasq -y > /dev/null & showSpinner
  echo
else
  echo -e $GREEN "  - DNSMasq has already been installed. :)" $BLACK
  echo
fi
# Check for error while running installation
if [ $? -ne 0 ]; then
  echo -e $RED "[!] An error occurred while installing dnsmasq!" $BLACK
  exit 1
fi


echo
echo -e $CYAN "Creating file structure to serve ..." $BLACK
echo

if [ ! -d /PXE ]; then
  echo
  echo -e $YELLOW "  - Creating the /PXE folder ..." $BLACK
  echo
  mkdir /PXE
else
  echo -e $GREEN "  - Folder /PXE already exists. :)" $BLACK
fi

if [ ! -d /PXE/filesystems ]; then
  echo
  echo -e $YELLOW "  - Creating the /PXE/filesystems folder ..." $BLACK
  echo
  mkdir /PXE/filesystems
else
  echo -e $GREEN "  - Folder /PXE/filesystems already exists. :)" $BLACK
fi

if [ ! -d /PXE/tftpboot ]; then
  echo
  echo -e $YELLOW "  - Creating the /PXE/tftpboot folder ..." $BLACK
  echo
  mkdir /PXE/tftpboot
else
  echo -e $GREEN "  - Folder /PXE/tftpboot already exists. :)" $BLACK
fi

echo
echo -e $GREEN "Done!" $BLACK
echo

exit 0
