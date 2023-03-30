#!/bin/bash
##################################################################
#    App Name: RPi-PXE                                           #
#      Author: PREngineer (Jorge Pabón) - pianistapr@hotmail.com #
#              https://www.github.com/PREngineer                 #
#   Publisher: Jorge Pabón                                       #
#     License: Non-Commercial Use - Free of Charge               #
#              ------------------------------------------------- #
#              Commercial use - Reach out to author for          #
#              licensing fees.                                   #
##################################################################

################### VARIABLES ###################

# Define the config file name
CONFIGFILE="RPi-PXE.conf"

# Location where we are executing
SCRIPTPATH=$(pwd)

# Color definition variables
BLACK='\e[0m'
CYAN='\e[36m'
YELLOW='\e[33m'
RED='\e[31m'
GREEN='\e[32m'
MAGENTA='\e[35m'

################### FUNCTIONS ###################

# This function is used to change the hostname of the PXE Server hostname
changeHostname(){
  # Clean the screen
  showHeader changeHostname

  echo -e $YELLOW"What would you like to name this Raspberry Pi? : "$BLACK
  read HOSTNAME

  echo $HOSTNAME > /etc/hostname
  echo
  echo -e $GREEN"Host name has been changed to $HOSTNAME"

  echo -e $YELLOW
  read -p "Press [Enter] to continue: "

  mainMenu
}

# This function deletes an image previously created
deleteImage(){
  showHeader deleteImage

  echo -e $YELLOW
  read -p " Please provide the image name to delete [e.g. Pi-1B-Bullseye-Clean-Install] : " IMAGENAME
  while [ ! -d /PXE/images/boot/${IMAGENAME} ]
  do
    showHeader deleteImage
    echo
    echo -e $RED " [!] - Couldn't find a folder with that image name!" $YELLOW
    echo
    read -p " Please provide the image name to delete [e.g. Pi-1B-Bullseye-Clean-Install] : " IMAGENAME
  done

  # Check with method we are using
  CHECK=$(cat $SCRIPTPATH/RPi-PXE.conf | grep Method | awk -F ":" '{print $2}')
  # If using NAS
  if [ $CHECK == '1' ]; then
    echo -e $MAGENTA
    echo " Deleting image folders: /NFSPXE/images/boot/${IMAGENAME} ..."
    rm -R /NFSPXE/images/boot/${IMAGENAME} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /NFSPXE/images/boot/${IMAGENAME}!" $BLACK
      exit 1
    fi
    echo

    echo " Deleting image folders: /NFSPXE/images/filesystems/${IMAGENAME}..."
    rm -R /NFSPXE/images/filesystems/${IMAGENAME} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /NFSPXE/images/filesystems/${IMAGENAME}!" $BLACK
      exit 1
    fi
  # Not using NAS
  else
    echo -e $MAGENTA
    echo " Deleting image folders: /PXE/images/boot/${IMAGENAME} ..."
    rm -R /PXE/images/boot/${IMAGENAME} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /PXE/images/boot/${IMAGENAME}!" $BLACK
      exit 1
    fi
    echo

    echo " Deleting image folders: /NFSPXE/images/filesystems/${IMAGENAME}..."
    rm -R /PXE/images/filesystems/${IMAGENAME} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /NFSPXE/images/filesystems/${IMAGENAME}!" $BLACK
      exit 1
    fi
  fi
  
  promptForEnter
  mainMenu
}

# This function deletes a provisioned pi's export and its contents
deleteProvisionedPi(){
  showHeader deleteProvisionedPi

  echo -e $YELLOW
  read -p " Please provide the serial number to delete [e.g. 7c65cd9d] : " SERIALNUMBER
  while [ ! -d /PXE/boot/${SERIALNUMBER} ] && [ ! -d /PXE/filesystems/${SERIALNUMBER} ]
  do
    showHeader deleteImage
    echo
    echo -e $RED " [!] - Couldn't find a folder with that image name!" $YELLOW
    echo
    read -p " Please provide the image name to delete [e.g. 7c65cd9d] : " SERIALNUMBER
  done

  # Check with method we are using
  CHECK=$(cat $SCRIPTPATH/RPi-PXE.conf | grep Method | awk -F ":" '{print $2}')
  # If using NAS
  if [ $CHECK == '1' ]; then
    echo -e $MAGENTA
    echo " Deleting the provisioned folder /NFSPXE/boot/${SERIALNUMBER} ..."
    rm -R /NFSPXE/boot/${SERIALNUMBER} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /NFSPXE/boot/${SERIALNUMBER}!" $BLACK
      exit 1
    fi
    echo

    echo -e $MAGENTA
    echo " Deleting the provisioned folder /NFSPXE/filesystems/${SERIALNUMBER} ..."
    rm -R /NFSPXE/filesystems/${SERIALNUMBER} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /NFSPXE/filesystems/${SERIALNUMBER}!" $BLACK
      exit 1
    fi
    echo

    echo -e $MAGENTA
    echo " Removing NFS export (${SERIALNUMBER}) from /etc/exports ..."
    sed -i "/$SERIALNUMBER/d" /etc/exports
    exportfs -ar
    sync
  # Not using NAS
  else
    echo -e $MAGENTA
    echo " Deleting the provisioned folder /PXE/boot/${SERIALNUMBER} ..."
    rm -R /PXE/boot/${SERIALNUMBER} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /PXE/boot/${SERIALNUMBER}!" $BLACK
      exit 1
    fi
    echo

    echo -e $MAGENTA
    echo " Deleting the provisioned folder /PXE/filesystems/${SERIALNUMBER} ..."
    rm -R /PXE/filesystems/${SERIALNUMBER} > /dev/null & showSpinner
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while deleting /PXE/filesystems/${SERIALNUMBER}!" $BLACK
      exit 1
    fi
    echo

    echo -e $MAGENTA
    echo " Removing NFS export (${SERIALNUMBER}) from /etc/exports ..."
    sed -i "/$SERIALNUMBER/d" /etc/exports
    exportfs -ar
    sync
  fi

  promptForEnter
  mainMenu
}

# This function is used to deploy a new Pi based on an image created previously
deployImage(){
  showHeader deployImage

  echo -e $YELLOW
  read -p " Please provide the image name to use [e.g. Pi-1B-Bullseye-Clean-Install] : " IMAGENAME
  while [ ! -d /PXE/images/boot/${IMAGENAME} ]
  do
    showHeader deployImage
    echo
    echo -e $RED " [!] - Image not found!" $YELLOW
    echo
    read -p " Please provide the image name to use [e.g. Pi-1B-Bullseye-Clean-Install] : " IMAGENAME
  done

  echo
  read -p " Please provide the serial number of the Rasbperry Pi to provision [e.g. 7c65cd9d] : " SERIALNUMBER

  # Check with method we are using
  CHECK=$(cat $SCRIPTPATH/RPi-PXE.conf | grep Method | awk -F ":" '{print $2}')
  # If using NAS
  if [ $CHECK == '1' ]; then
    echo -e $MAGENTA
    echo " Making directory /NFSPXE/boot/${SERIALNUMBER} ..."
    if [ ! -d /NFSPXE/boot/${SERIALNUMBER} ]; then
      mkdir /NFSPXE/boot/${SERIALNUMBER}
      echo
      echo " Copying boot files from /NFSPXE/images/boot/${IMAGENAME} to folder /NFSPXE/boot/${SERIALNUMBER}"
      sudo cp -r /NFSPXE/images/boot/${IMAGENAME}/* /NFSPXE/boot/${SERIALNUMBER}/
    else
      echo -e $RED
      echo " [!] This serial number has already been provisioned.  Deprovision it before trying"
      echo " to provision it again."
      promptForEnter
      mainMenu
    fi
    
    echo
    echo " Making directory /NFSPXE/filesystems/${SERIALNUMBER} ..."
    if [ ! -d /NFSPXE/filesystems/${SERIALNUMBER} ]; then
      echo 
      echo " Copying boot files from /NFSPXE/images/filesystems/${IMAGENAME} to folder /NFSPXE/filesystems/${SERIALNUMBER}"
      rsync -xa --progress /NFSPXE/images/filesystems/${IMAGENAME} /NFSPXE/filesystems/
      sudo mv /NFSPXE/filesystems/${IMAGENAME} /NFSPXE/filesystems/${SERIALNUMBER}
    else
      echo -e $RED
      echo " [!] This serial number has already been provisioned.  Deprovision it before trying"
      echo " to provision it again."
      promptForEnter
      mainMenu
    fi

    echo -e $YELLOW
    read -p " Please provide the IP of the NFS server [e.g. 10.0.0.50] : " NFSIP
    read -p " Please provide the NFS share mount point [e.g. /volume1/PXE] : " MOUNTPOINT
    echo -e $MAGENTA
    echo " Changing the /boot/cmdline.txt to boot from the NFS directory ..."
    sed -i "s|\(^.*root=\).*$|\1/dev/nfs nfsroot=${NFSIP}:${MOUNTPOINT}/filesystems/${SERIALNUMBER},vers=4.1,proto=tcp rw ip=dhcp rootwait elevator=deadline|" "/NFSPXE/boot/${SERIALNUMBER}/cmdline.txt"
  
    echo -e $MAGENTA
    echo " Clearing old mount directives from /etc/fstab ..."
    sed -i '/ \/boot /d' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"
    sed -i '/ \/ /d' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"

    echo -e $MAGENTA
    echo " Adding new mount directives to /etc/fstab ..."
    echo "" >> "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "# NFS Share - File System" >> "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "${NFSIP}:${MOUNTPOINT}/boot/${SERIALNUMBER} /boot nfs defaults,vers=4.1,proto=tcp 0 0" >> "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "${NFSIP}:${MOUNTPOINT}/filesystems/${SERIALNUMBER} /     nfs defaults,vers=4.1,proto=tcp 0 0" >> "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "# NFS" >> "/NFSPXE/filesystems/${SERIALNUMBER}/etc/fstab"

    echo
    echo " Making sure partition resizing is not enabled ..."
    if [ -f "/NFSPXE/filesystems/${SERIALNUMBER}/etc/resize-root-fs" ]; then
      sed -i '/resize-root-fs/d' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/rc.local"
      rm "/NFSPXE/filesystems/${SERIALNUMBER}/etc/resize-root-fs"
    fi
    if [ -f "/NFSPXE/filesystems/${SERIALNUMBER}/etc/init.d/resize2fs_once" ]; then
      sed -i '/resize2fs /d' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/init.d/resize2fs_once"
    fi

    echo
    echo " Making sure SSH is enabled ..."
    if [ "$(find "/NFSPXE/boot/${SERIALNUMBER}/" -type f -iregex "/NFSPXE/boot/${SERIALNUMBER}/ssh\(\.txt\)?" -print -delete)" != "" ]; then
      if [ $(grep -c 'pxe-enable-ssh' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/rc.local") -eq 0 ]; then
        echo "
		      #!/bin/bash
		      update-rc.d ssh enable && invoke-rc.d ssh start
	  	    sed -i '/pxe-enable-ssh/d' /etc/rc.local
  		    rm /etc/pxe-enable-ssh " > "/NFSPXE/filesystems/${SERIALNUMBER}/etc/pxe-enable-ssh"

        chmod +x "/NFSPXE/filesystems/${SERIALNUMBER}/etc/pxe-enable-ssh"
        sed -i 's|^exit 0$|/etc/pxe-enable-ssh\nexit 0|' "/NFSPXE/filesystems/${SERIALNUMBER}/etc/rc.local"
      fi
    fi

    echo -e $YELLOW
    read -p " Do you want to restrict access to this filesystem? [y/n] : " RESTRICT    
    if [ $RESTRICT == 'y' ] || [ $RESTRICT == 'Y' ]; then
      echo
      echo " You can restrict access the following ways:"
      echo "   1. To a specific IP address [e.g. 10.0.0.30]"
      echo "   2. To a network range ( [Network Address]/[Network Mask]) [e.g. 10.0.0.0/24]"
      echo
      read -p " How do you want to restrict access : " ACCESS
      while [ $ACCESS != 1 ] && [ $ACCESS != 2 ]
      do
        echo -e $RED "[!] - Invalid option provided!" $YELLOW
        read -p " How do you want to restrict access : " ACCESS
      done

      if [ $ACCESS == '1' ]; then
        echo
        read -p " Please provide the IP address that will have access [e.g. 10.0.0.30] : " CLIENTIP
      fi
      if [ $ACCESS == '2' ]; then
        echo
        read -p " Please provide the network address range that will have access [e.g. 10.0.0.0/24] : " CLIENTIP
      fi
      echo -e $CYAN "Access will be granted to $CLIENTIP."
    else
      echo -e $CYAN "Access will be granted to all devices."
      CLIENTIP=*
    fi
    echo
    echo " Creating NFS exports ..."
    echo "/NFSPXE/boot/${SERIALNUMBER} ${CLIENTIP}(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -ar
    sync

  # If using other methods
  else
    echo -e $MAGENTA
    echo " Making directory /PXE/boot/${SERIALNUMBER} ..."
    if [ ! -d /PXE/boot/${SERIALNUMBER} ]; then
      mkdir /PXE/boot/${SERIALNUMBER}
      echo
      echo " Copying boot files from /PXE/images/boot/${IMAGENAME} to folder /PXE/boot/${SERIALNUMBER}"
      sudo cp -r /PXE/images/boot/${IMAGENAME}/* /PXE/boot/${SERIALNUMBER}/
    else
      echo -e $RED
      echo " [!] This serial number has already been provisioned.  Deprovision it before trying"
      echo " to provision it again."
      promptForEnter
      mainMenu
    fi
    
    echo
    echo " Making directory /PXE/filesystems/${SERIALNUMBER} ..."
    if [ ! -d /PXE/filesystems/${SERIALNUMBER} ]; then
      echo 
      echo " Copying boot files from /PXE/images/filesystems/${IMAGENAME} to folder /PXE/filesystems/${SERIALNUMBER}"
      rsync -xa --progress /PXE/images/filesystems/${IMAGENAME} /PXE/filesystems/
      sudo mv /PXE/filesystems/${IMAGENAME} /PXE/filesystems/${SERIALNUMBER}
    else
      echo -e $RED
      echo " [!] This serial number has already been provisioned.  Deprovision it before trying"
      echo " to provision it again."
      promptForEnter
      mainMenu
    fi

    NETWORKINFO=$(ip -4 addr show dev eth0 | grep inet)
    NFSIP=$(sed -nr 's|.*inet ([^ ]+)/.*|\1|p' <<< ${NETWORKINFO})
    NFSMOUNTPOINT=/PXE

    echo -e $MAGENTA
    echo " Changing the /boot/cmdline.txt to boot from the NFS directory ..."
    sed -i "s|\(^.*root=\).*$|\1/dev/nfs nfsroot=${NFSIP}:${NFSMOUNTPOINT}/filesystems/${SERIALNUMBER},vers=4.1,proto=tcp rw ip=dhcp rootwait elevator=deadline|" "/PXE/boot/${SERIALNUMBER}/cmdline.txt"
  
    echo -e $MAGENTA
    echo " Clearing old mount directives from /etc/fstab ..."
    sed -i '/ \/boot /d' "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"
    sed -i '/ \/ /d' "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"

    echo -e $MAGENTA
    echo " Adding new mount directives to /etc/fstab ..."
    echo "" >> "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "# NFS Share - File System" >> "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "${NFSIP}:${NFSMOUNTPOINT}/boot/${SERIALNUMBER} /boot nfs defaults,vers=4.1,proto=tcp 0 0" >> "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "${NFSIP}:${NFSMOUNTPOINT}/filesystems/${SERIALNUMBER} /     nfs defaults,vers=4.1,proto=tcp 0 0" >> "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"
    echo "# NFS" >> "/PXE/filesystems/${SERIALNUMBER}/etc/fstab"

    echo
    echo " Making sure partition resizing is not enabled ..."
    if [ -f "/PXE/filesystems/${SERIALNUMBER}/etc/resize-root-fs" ]; then
      sed -i '/resize-root-fs/d' "/PXE/filesystems/${SERIALNUMBER}/etc/rc.local"
      rm "/PXE/filesystems/${SERIALNUMBER}/etc/resize-root-fs"
    fi
    if [ -f "/PXE/filesystems/${SERIALNUMBER}/etc/init.d/resize2fs_once" ]; then
      sed -i '/resize2fs /d' "/PXE/filesystems/${SERIALNUMBER}/etc/init.d/resize2fs_once"
    fi

    echo
    echo " Making sure SSH is enabled ..."
    if [ "$(find "/PXE/boot/${SERIALNUMBER}/" -type f -iregex "/PXE/boot/${SERIALNUMBER}/ssh\(\.txt\)?" -print -delete)" != "" ]; then
      if [ $(grep -c 'pxe-enable-ssh' "/PXE/filesystems/${SERIALNUMBER}/etc/rc.local") -eq 0 ]; then
        echo "
		      #!/bin/bash
		      update-rc.d ssh enable && invoke-rc.d ssh start
	  	    sed -i '/pxe-enable-ssh/d' /etc/rc.local
  		    rm /etc/pxe-enable-ssh " > "/PXE/filesystems/${SERIALNUMBER}/etc/pxe-enable-ssh"

        chmod +x "/PXE/filesystems/${SERIALNUMBER}/etc/pxe-enable-ssh"
        sed -i 's|^exit 0$|/etc/pxe-enable-ssh\nexit 0|' "/PXE/filesystems/${SERIALNUMBER}/etc/rc.local"
      fi
    fi

    echo -e $YELLOW
    read -p " Do you want to restrict access to this filesystem? [y/n] : " RESTRICT    
    if [ $RESTRICT == 'y' ] -or [ $RESTRICT == 'Y' ]; then
      echo
      echo " You can restrict access the following ways:"
      echo "   1. To a specific IP address [e.g. 10.0.0.30]"
      echo "   2. To a network range ( [Network Address]/[Network Mask]) [e.g. 10.0.0.0/24]"
      echo
      read -p " How do you want to restrict access : " ACCESS
      while [ $ACCESS != 1 ] && [ $ACCESS != 2 ]
      do
        echo -e $RED "[!] - Invalid option provided!" $YELLOW
        read -p " How do you want to restrict access : " ACCESS
      done

      if [ $ACCESS == '1' ]; then
        echo
        read -p " Please provide the IP address that will have access [e.g. 10.0.0.30] : " CLIENTIP
      fi
      if [ $ACCESS == '2' ]; then
        echo
        read -p " Please provide the network address range that will have access [e.g. 10.0.0.0/24] : " CLIENTIP
      fi
      echo -e $CYAN "Access will be granted to $CLIENTIP."
    else
      echo -e $CYAN "Access will be granted to all devices."
      CLIENTIP=*
    fi
    echo
    echo " Creating NFS exports ..."
    echo "/PXE/boot/${SERIALNUMBER} ${CLIENTIP}(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -ar
    sync
  fi

  echo -e $GREEN
  echo " Raspberry Pi has been provisioned.  :)"
  
  promptForEnter
  mainMenu
}

# This function is used to retrieve information about a Raspberry Pi in the network
getDetailsAboutPi(){

  showHeader otherPiDetails

  echo -e $CYAN "Please provide the information that will be requested next, we need it to connect "
  echo " to the Raspberry Pi."
  
  echo -e $YELLOW
  read -p " What is the IP of the Raspberry Pi to check? [e.g. 10.0.0.30] : " PIIP
  read -p " What is the username used to log into this Pi? [e.g. pi] : " USER
  echo -e $CYAN

  echo "
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '                                             Basic Information'
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '- Hostname -' 
  sudo cat /etc/hostname
  echo
  echo '- OS Version -'
  sudo cat /etc/os-release | grep VERSION= | awk -F '=\"' '{print \$2}' | sed 's/\"//g'
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '                                             Hardware Information'
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '- RPI Model -'
  sudo cat /proc/cpuinfo | grep Model | awk -F ': ' '{print \$2}'
  echo
  echo '- ARM Version -'
  sudo cat /proc/cpuinfo | grep 'model name' | awk -F ': ' '{print \$2}'
  echo
  echo '- Serial Number -'
  sudo cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | cut -c 9-16
  echo
  echo '- Mac Address -'
  sudo ifconfig | grep ether | awk '{print \$2}'
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '                                            Network Information'
  echo '-----------------------------------------------------------------------------------------------------------'
  echo '- IP Address -'
  echo ${PIIP}
  echo '-----------------------------------------------------------------------------------------------------------'" >> script.sh

  chmod +x script.sh
  ssh ${USER}@${PIIP} 'bash -s' < script.sh
  rm script.sh

  promptForEnter

  mainMenu
}

# This function shows a list of all pis on the network
identifyPis(){
  showHeader networkScan
  
  echo -e $RED" -----------------------------------------------------------------------------------------------------------"
  echo " To identify all the Raspberry Pi devices in our network, we need to populate this Raspberry Pi's ARP table."
  echo " We'll do it by pinging all devices in our network.  Assuming a default network of netmask /24, that is 253 IPs."
  echo
  echo " IT WILL TAKE TIME.  Please be patient."
  echo " -----------------------------------------------------------------------------------------------------------"

  NETWORKINFO=$(ip -4 addr show dev eth0 | grep inet)
  GATEWAY=$(ip route | awk '/default/ {print $3}')
  BASEIP=$(echo $GATEWAY | awk -F '.' '{ print $1"."$2"."$3"." }')

  echo -e $MAGENTA
  echo " Pinging IP addresses in the network ..."
  
  # Ping all devices in our network to populate the ARP table
  for i in {1..254} ;do (ping $BASEIP$i -c 1 >/dev/null && echo "   * Response received from device: $BASEIP$i" &) ;done

  showHeader networkScan

  echo -e $CYAN "These are the Raspberry Pi devices found during the scan:"
  echo " -----------------------------------------------------------------------------------------------------------"
  # Print the list of Pis
  arp -a | grep -E --ignore-case 'b8:27:eb|dc:a6:32' | awk '{print " "$1" "$2}'
  echo " -----------------------------------------------------------------------------------------------------------"

  promptForEnter
  mainMenu
}

# This function is to do the installation process
installPXE(){
  # Clean the screen
  showHeader install

  ################### Part 1 - Update and install dependencies ###################
  echo
  echo -e $MAGENTA "Updating list of packages ..." $BLACK
  echo
  apt-get update -y > /dev/null & showSpinner
  echo
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while updating the package indexes!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Upgrading packages ..." $BLACK
  echo
  apt-get upgrade -y > /dev/null & showSpinner
  echo
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while upgrading the packages!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Upgrading system ..." $BLACK
  echo
  apt-get dist-upgrade -y > /dev/null & showSpinner
  echo
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while upgrading the system!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Checking installion of NFS Kernel Server ..." $BLACK
  echo
  NFS_STATUS=$(dpkg-query -W --showformat='${Status}\n' nfs-kernel-server|grep "install ok installed")
  if [ "" = "$NFS_STATUS" ]; then
    echo -e $YELLOW "  - NFS Kernel Server is not installed yet. It will be installed now ..." $BLACK
    echo
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
  echo -e $MAGENTA "Checking installion of Samba ..." $BLACK
  echo
  SAMBA_STATUS=$(dpkg-query -W --showformat='${Status}\n' samba-common|grep "install ok installed")
  if [ "" = "$SAMBA_STATUS" ]; then
    echo -e $YELLOW "  - Samba is not installed yet. It will be installed now ..." $BLACK
    echo
    apt-get install samba -y > /dev/null & showSpinner
    echo
  else
    echo -e $GREEN "  - Samba has already been installed. :)" $BLACK
    echo
  fi
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while installing Samba!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Checking installion of CIFS-Utils ..." $BLACK
  echo
  CIFS_STATUS=$(dpkg-query -W --showformat='${Status}\n' cifs-utils|grep "install ok installed")
  if [ "" = "$CIFS_STATUS" ]; then
    echo -e $YELLOW "  - CIFS-Utils is not installed yet. It will be installed now ..." $BLACK
    echo
    apt-get install cifs-utils -y > /dev/null & showSpinner
    echo
  else
    echo -e $GREEN "  - CIFS-Utils has already been installed. :)" $BLACK
    echo
  fi
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while installing CIFS-Utils!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Installing DNSMasq ..." $BLACK
  echo
  DNSMASQ_STATUS=$(dpkg-query -W --showformat='${Status}\n' dnsmasq|grep "install ok installed")
  if [ "" = "$DNSMASQ_STATUS" ]; then
    echo -e $YELLOW "  - DNSMasq is not installed yet. It will be installed now ..." $BLACK
    echo
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
  echo -e $MAGENTA "Removing unused packages ..." $BLACK
  echo
  apt-get autoremove -y > /dev/null & showSpinner
  echo

  promptForEnter

  ################### Part 2 - Determine how we will be running the system ###################

  showHeader install

  echo -e $RED
  echo "-----------------------------------------------------------------------------------------------------------"
  echo "                                           PLEASE READ THIS CAREFULLY"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo " This PXE server will be constantly writing to and reading from directories that we will create to hold the"
  echo " filesystems of all the Raspberry Pis that we will service."
  echo
  echo " YOU SHOULD NOT ATTEMPT TO DO IT USING AN SD CARD."
  echo 
  echo "   * You would need a pretty big SD Card if you want to go that route."
  echo "   * Additionally, the SD Cards's life will likely be very short."
  echo "-----------------------------------------------------------------------------------------------------------"
  
  echo -e $CYAN
  echo " Given the warning above, there are options available to you.  You could: "
  echo
  echo "  1. Use a NAS server to store and serve files using Samba and NFS (recommended)"
  echo "  2. Mount and use a hard drive to store the files (connected to this Raspberry Pi)"
  echo "  3. Use the boot device (either your SD Card or Hard Disk, if you are booting from one)"
  echo -e $YELLOW
  read -p " How would you like to proceed? : " METHOD
  while [[ $METHOD != '1' && $METHOD != '2' && $METHOD != '3' ]]
  do
    echo -e $RED "[!] - Invalid option!" $YELLOW
    read -p " How would you like to proceed? : " METHOD
  done

  # Store method in our config file
  echo "Method:${METHOD}" > ${CONFIGFILE}

  ################### Part 2 - Describe file structure ###################

  showHeader install

  echo -e $CYAN
  echo " We will be creating the following file structure:"
  echo 
  echo " /                        <-- Root of your Raspberry Pi (SD Card or Drive)"
  case $METHOD in
    1)
      echo " ├─ PXE (NFSPXE)          <-- The root of your Samba (NFS) share will be mounted here"
      ;;
    2)
      echo " ├─ PXE                   <-- The root of your hard drive will be mounted here"
      ;;
    3)
      echo " ├─ PXE                   <-- We will create this folder in the boot device"
      ;;
  esac  
  echo "    ├─ boot               <-- Contains the boot partitions we will serve"
  echo "       ├─ <serial number> <-- Contains the boot files for the Raspberry Pi with that serial number"
  echo "       ├─ ..."
  echo "    ├─ filesystems        <-- Contains the linux filesystem partitions we will serve"
  echo "       ├─ <serial number> <-- Contains the linux filesystem for the Raspberry Pi with that serial number"
  echo "       ├─ ..."
  echo "    ├─ images             <-- Contains the images of Raspberry Pis that we create"
  echo "       ├─ boot            <-- Contains the boot files of the images created"
  echo "          ├─ <IMG NAME>   <-- Contains the boot files for the image specified"
  echo "          ├─ ..."
  echo "       ├─ filesystems     <-- Contains the linux filesystem files of the images created"
  echo "          ├─ <IMG NAME>   <-- Contains the linux filesystem for the image specified"
  echo "          ├─ ..."
  if [ $METHOD -eq '1' ]; then
    echo -e $RED
    echo "-----------------------------------------------------------------------------------------------------------"
    echo " Before proceeding, please create the Samba and NFS share in your Network Attached Storage."
    echo " We suggest that you name it  << PXE >> as it is easy to remember what it is being used for."
    echo
    echo " Why do we need Samba?"
    echo " The RPi-PXE server can't re-export a mounted NFS share.  The boot files' permissions are not relevant."
    echo " We will export the share (using NFS) to initiate the boot process of the Raspberry Pis upon receiving"
    echo " the broadcasted PXE request."
    echo
    echo " Why do we need NFS?"
    echo " The linux filesystem must be copied and accessed through NFS to keep the permisions."
    echo " The RPi-PXE server needs to mount this to successfully deploy images for new Raspberry Pis."
    echo " These files will be served by our NAS server, we will just let the Raspberry Pis know where they are."
    echo "-----------------------------------------------------------------------------------------------------------"
  fi
  
  echo
  if [ ! -d /PXE ]; then
    echo -e $YELLOW "  - Creating the /PXE folder ..." $BLACK
    echo
    mkdir /PXE
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE already exists. :)" $BLACK
    echo
  fi

  promptForEnter
  
  ################### Part 3 - Mount the hard disk (Method 2) ###################

  if [ $METHOD -eq '2' ]; then
    showHeader install
  
    echo -e $RED
    echo " -----------------------------------------------------------------------------------------------------------"
    echo " If you have not already done so, please plug the Hard Disk into the Raspberry Pi."
    echo " -----------------------------------------------------------------------------------------------------------"
    echo -e $CYAN
    echo " Please pay attention to the following list of devices, we need to identify the device name of our hard "
    echo " disk.  Ignore the memory card entries that usually are named something like: /dev/mmcblk0..."
    echo " The hard drives or USB drives are usually named something like: /dev/sda or /dev/sda1"
    echo -e $YELLOW
    sudo blkid -o device
    echo
    read -p " Please provide the name of the drive [e.g. /dev/sda1] : " DRIVE

    echo -e $CYAN
    echo " Formatting the drive ${DRIVE} as EXT4 ..."
    echo -e $YELLOW
    mkfs -t ext4 ${DRIVE}

    echo -e $CYAN
    echo " Adding the drive mount to /etc/fstab ..."
    echo "   ${DRIVE} /PXE ext4 defaults 0 0"
    echo "${DRIVE} /PXE ext4 defaults,auto,users,rw,nofail 0 0" >> /etc/fstab

    echo
    echo " Mounting the drive ..."
    mount -a
    
    CHECK=$(df -h | grep /PXE)
    if [ ! -z "$CHECK" ]; then
      echo -e $GREEN
      echo " Perfect!  The mount was succesfully validated.  :)"
    fi    
    promptForEnter
  fi
  
  ################### Part 4 - Creating the file structure ###################

  showHeader install

  echo
  echo -e $MAGENTA "Creating file structure to serve ..." $BLACK
  echo
  if [ ! -d /PXE/boot ]; then
    echo -e $YELLOW "  - Creating the /PXE/boot folder ..." $BLACK
    echo
    mkdir /PXE/boot
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE/boot folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE/boot already exists. :)" $BLACK
    echo
  fi
  if [ ! -d /PXE/filesystems ]; then
    echo -e $YELLOW "  - Creating the /PXE/filesystems folder ..." $BLACK
    echo
    mkdir /PXE/filesystems
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE/filesystems folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE/filesystems already exists. :)" $BLACK
    echo
  fi
  if [ ! -d /PXE/images ]; then
    echo -e $YELLOW "  - Creating the /PXE/images folder ..." $BLACK
    echo
    mkdir /PXE/images
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE/images folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE/images already exists. :)" $BLACK
    echo
  fi
  if [ ! -d /PXE/images/boot ]; then
    echo -e $YELLOW "  - Creating the /PXE/images/boot folder ..." $BLACK
    echo
    mkdir /PXE/images/boot
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE/images/boot folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE/images/boot already exists. :)" $BLACK
    echo
  fi
  if [ ! -d /PXE/images/filesystems ]; then
    echo -e $YELLOW "  - Creating the /PXE/images/filesystems folder ..." $BLACK
    echo
    mkdir /PXE/images/filesystems
    # Check for error
    if [ $? -ne 0 ]; then
      echo -e $RED "[!] An error occurred while creating the /PXE/images/filesystems folder!" $BLACK
      exit 1
    fi
  else
    echo -e $GREEN "  - Folder /PXE/images/filesystems already exists. :)" $BLACK
    echo
  fi
  chmod -R 777 /PXE
  
  # If using NFS/Samba
  if [ $METHOD -eq '1' ]; then
    if [ ! -d /NFSPXE ]; then
      echo -e $YELLOW "  - Creating the /NFSPXE folder ..." $BLACK
      echo
      mkdir /NFSPXE
      # Check for error
      if [ $? -ne 0 ]; then
        echo -e $RED "[!] An error occurred while creating the /NFSPXE folder!" $BLACK
        exit 1
      fi
      chmod -R 777 /NFSPXE
    fi
  fi

  ################### Part 5 - Prompt for NFS/Samba information ###################

  if [ $METHOD -eq '1' ]; then

    showHeader install

    echo -e $CYAN
    echo " Please, provide the following information to mount your Samba and NFS shares into the RPi-PXE Server ..."
    echo -e $YELLOW
    read -p " NAS IP Address [e.g. 10.0.0.50] : " NASIP
    read -p " NFS Mount Path [e.g. /volume1/PXE] : " NFSMOUNTPATH
    read -p " Samba Share Name [e.g. /PXE] : " SAMBAMOUNTPATH
    read -p " Samba Username : " USER
    read -s -p " Samba Password : " PASS
    echo

    echo "NASIP:${NASIP}" >> $CONFIGFILE
    echo "NFSMOUNT:${NFSMOUNTPATH}" >> $CONFIGFILE
    echo "SAMBAMOUNT:${SAMBAMOUNTPATH}" >> $CONFIGFILE
    echo "NASUSER:${USER}" >> $CONFIGFILE
    echo "NASPASSWORD:${PASS}" >> $CONFIGFILE
  
    echo -e $MAGENTA "  - Adding Samba share to our /etc/fstab ..." $BLACK
    echo
    # Check if we've set it up before
    CHECK=$(cat /etc/fstab | grep /PXE)
    if [ ! -z "$CHECK" ]; then
      echo -e $YELLOW"    * Found old Samba mount point: "
      echo
      echo -e $YELLOW"      "$CHECK
      echo
      echo -e $CYAN"    * Will replace it with:"
      echo
      echo "      //$NASIP$SAMBAMOUNTPATH /PXE cifs username=<USER>,password=<PASSWORD>,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"
      sed "s*$CHECK*//$NASIP$SAMBAMOUNTPATH /PXE cifs username=${USER},password=${PASS},iocharset=utf8,file_mode=0777,dir_mode=0777 0 0*g" -i /etc/fstab
      echo
    else
      echo -e $MAGENTA"    * Adding the following Samba mount point:"
      echo
      echo "      //$NASIP$SAMBAMOUNTPATH /PXE cifs username=<USER>,password=<PASSWORD>,iocharset=utf8,file_mode=0777,dir_mode=0777 0 0"
      echo "# Samba Shares" >> /etc/fstab
      echo "//$NASIP$SAMBAMOUNTPATH /PXE cifs username=${USER},password=${PASS},iocharset=utf8,file_mode=0777,dir_mode=0777 0 0" >> /etc/fstab
      echo "# Samba" >> /etc/fstab
      echo
    fi

    # Unmount previous if any
    if [ ! -z "$CHECK" ]; then
      echo -e $MAGENTA "  - Unmounting the previous Samba share from our filesystem ..." $BLACK
      CHECK=$(df -h | grep /PXE | awk '{print $1}')
      umount /PXE > /dev/null
      if [ ! -d /PXE ]; then
        mkdir /PXE > /dev/null
      fi
      if [ ! -d /PXE/boot ]; then
        mkdir /PXE/boot > /dev/null
      fi
      if [ ! -d /PXE/filesystems ]; then
        mkdir /PXE/filesystems > /dev/null
      fi
      echo
    fi

    echo -e $MAGENTA "  - Adding NFS share to our /etc/fstab ..." $BLACK
    echo
    # Check if we've set it up before
    CHECK=$(cat /etc/fstab | grep /NFSPXE)
    if [ ! -z "$CHECK" ]; then
      echo -e $YELLOW"    * Found old NFS mount point: "
      echo
      echo -e $YELLOW"      "$CHECK
      echo
      echo -e $CYAN"    * Will replace it with:"
      echo
      echo "      $NASIP:$NFSMOUNTPATH /NFSPXE nfs defaults,vers=4.1,proto=tcp 0 0"
      sed "s*$CHECK*$NASIP:$NFSMOUNTPATH /NFSPXE nfs defaults,vers=4.1,proto=tcp 0 0*g" -i /etc/fstab
      echo
    else
      echo -e $MAGENTA"    * Adding the following NFS mount point:"
      echo
      echo "      $NASIP:$NFSMOUNTPATH /NFSPXE nfs defaults,vers=4.1,proto=tcp 0 0"
      echo "# NFS Shares" >> /etc/fstab
      echo "$NASIP:$NFSMOUNTPATH /NFSPXE nfs defaults,vers=4.1,proto=tcp 0 0" >> /etc/fstab
      echo "# NFS" >> /etc/fstab
      echo
    fi

    # Unmount previous if any
    if [ ! -z "$CHECK" ]; then
      echo -e $MAGENTA "  - Unmounting the previous NFS share from our filesystem ..." $BLACK
      CHECK=$(df -h | grep /NFSPXE | awk '{print $1}')
      umount /PXE > /dev/null
    fi
  
    echo -e $MAGENTA "  - Mounting the Samba and NFS shares to our filesystem ..." $BLACK
      mount -a
    echo

    if [ ! -d /PXE/filesystems ]; then
      echo -e $MAGENTA "  - Creating the /PXE/filesystems folder ..." $BLACK
      echo
      if [ ! -d /PXE/filesystems ]; then
        mkdir /PXE/filesystems > /dev/null
      fi
      # Check for error
      if [ $? -ne 0 ]; then
        echo -e $RED "[!] An error occurred while creating the /PXE/filesystems folder!" $BLACK
        exit 1
      fi
    else
      echo -e $GREEN "  - Folder /PXE/filesystems already exists. :)" $BLACK
      echo
    fi

    if [ ! -d /PXE/boot ]; then
      echo -e $MAGENTA "  - Creating the /PXE/boot folder ..." $BLACK
      echo
      mkdir /PXE/boot > /dev/null
      # Check for error
      if [ $? -ne 0 ]; then
        echo -e $RED "[!] An error occurred while creating the /PXE/boot folder!" $BLACK
        exit 1
      fi
      cp /boot/bootcode.bin /PXE/boot
    else
      echo -e $GREEN "  - Folder /PXE/boot already exists. :)" $BLACK
      cp /boot/bootcode.bin /PXE/boot
      echo
    fi

    if [ ! -d /PXE/images ]; then
      echo -e $MAGENTA "  - Creating the /PXE/images folder ..." $BLACK
      echo
      mkdir /PXE/images > /dev/null
      mkdir /PXE/images/boot > /dev/null
      mkdir /PXE/images/filesystems > /dev/null
      # Check for error
      if [ $? -ne 0 ]; then
        echo -e $RED "[!] An error occurred while creating the /PXE/images folder!" $BLACK
        exit 1
      fi
    else
      echo -e $GREEN "  - Folder /PXE/images already exists. :)" $BLACK
      echo
    fi
  fi

  # If using method's 2 or 3, we need to export the /PXE folder structure
  if [ $METHOD -eq '2' ] || [ $METHOD -eq '3' ]; then
    echo
    echo -e $MAGENTA "Sharing /PXE over NFS ..."
    CLIENTIP=*
    echo "/PXE *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -ar
    sync
  fi
    
  echo
  echo -e $GREEN "Done!"
  echo

  promptForEnter

  ################### Part 6 - Preparing configuration files ###################
  showHeader install

  echo
  echo -e $MAGENTA "Preparing the DNSMasq configuration file ..." $BLACK
  echo
  NETWORKINFO=$(ip -4 addr show dev eth0 | grep inet)
  BRD=$(sed -n 's|^.*\s*brd\s\+\(\S\+\)\s.*|\1|p' <<< ${NETWORKINFO})
  # Append to the configuration file
  # Set the Broadcast address of our network (to listen in).  Set the PXE service for Raspberry Pis.  Set the root of the TFTP server to our boot folder.
  echo "# Start DNSMasq service configuration" > /etc/dnsmasq.conf
  echo "port=0" >> /etc/dnsmasq.conf
  echo "dhcp-range=$BRD,proxy" >> /etc/dnsmasq.conf
  echo "log-dhcp" >> /etc/dnsmasq.conf
  echo "enable-tftp" >> /etc/dnsmasq.conf
  echo "tftp-root=/PXE/boot" >> /etc/dnsmasq.conf
  echo 'pxe-service=0,"Raspberry Pi Boot"' >> /etc/dnsmasq.conf
  echo "# End DNSMasq" >> /etc/dnsmasq.conf

  echo
  echo -e $MAGENTA "Preparing the 10-eth0 network configuration file ..." $BLACK
  echo
  echo "# Start 10-eth0 configuration" > /etc/systemd/network/10-eth0.netdev
  echo "[Match]" >> /etc/systemd/network/10-eth0.netdev
  echo "Name=eth0" >> /etc/systemd/network/10-eth0.netdev
  echo "" >> /etc/systemd/network/10-eth0.netdev
  echo "[Network]" >> /etc/systemd/network/10-eth0.netdev
  echo "DHCP=no" >> /etc/systemd/network/10-eth0.netdev
  echo "# End 10-eth0 configuration" >> /etc/systemd/network/10-eth0.netdev

  echo
  echo -e $MAGENTA "Preparing the 11-eth0 network configuration file ..." $BLACK
  echo
  INET=$(sed -n 's|^\s*inet\s\+\(\S\+\)\s.*|\1|p' <<< ${NETWORKINFO})
  GATEWAY=$(ip route | awk '/default/ {print $3}')
  DNS_SRV=${GATEWAY}
  echo "# Start 10-eth0 configuration" > /etc/systemd/network/11-eth0.netdev
  echo "[Match]" >> /etc/systemd/network/11-eth0.netdev
  echo "Name=eth0" >> /etc/systemd/network/11-eth0.netdev
  echo "" >> /etc/systemd/network/11-eth0.netdev
  echo "[Network]" >> /etc/systemd/network/11-eth0.netdev
  echo "Address=$INET" >> /etc/systemd/network/11-eth0.netdev
  echo "DNS=$DNS_SRV" >> /etc/systemd/network/11-eth0.netdev
  echo "" >> /etc/systemd/network/11-eth0.netdev
  echo "[Route]" >> /etc/systemd/network/11-eth0.netdev
  echo "Gateway=$GATEWAY" >> /etc/systemd/network/11-eth0.netdev
  echo "# End 10-eth0 configuration" >> /etc/systemd/network/11-eth0.netdev

  echo
  echo -e $MAGENTA "Adding our DNS Server to the resolved configuration file ..." $BLACK
  echo
  sed -i "s|^#DNS=$|DNS=${DNS_SRV}|" /etc/systemd/resolved.conf
  
  ################### Part 7 - Enable the Services ###################

  echo
  echo -e $MAGENTA "Enabling the system services ..." $BLACK
  echo
  systemctl enable dnsmasq &> /dev/null && \
  systemctl enable dnsmasq.service &> /dev/null && \
  systemctl enable rpcbind &> /dev/null && \
  systemctl enable nfs-kernel-server &> /dev/null && \
  systemctl enable samba &> /dev/null && \
  systemctl enable systemd-networkd &> /dev/null & showSpinner
  # Check for error
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while enabling the services!" $BLACK
    exit 1
  fi

  echo
  echo -e $RED 
  echo "-----------------------------------------------------------------------------------------------------------"
  echo -e "                      We need to restart the machine before we can use it!"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo
  promptForEnter
  reboot now
}

# This function is used to display the menu
mainMenu(){
  # Clean the screen
  showHeader

  echo
  echo -e $CYAN"Welcome to RPi-PXE!"
  echo
  echo -e " --------------------------------------------- RPi-PXE Server ----------------------------------------------"
  echo -e " 1) Install the RPi-PXE server"
  echo -e " 2) Uninstall the RPi-PXE server"
  echo -e " 3) See information about this Pi"
  echo -e " 4) Change the hostname of this Pi"
  echo -e " ------------------------------------------ Other Pis In Network -------------------------------------------"
  echo -e " 5) Identify Pis in the network"
  echo -e " 6) Get details about a Pi in the network"
  echo -e " -------------------------------------------- Images & Live Pis --------------------------------------------"
  echo -e " 7) Make an image of a Pi"
  echo -e " 8) Provision a new Pi using an image"
  echo -e " 9) Delete an image of a Pi"
  echo -e "10) Delete provisioned Pi from Server"
  echo -e " --------------------------------------------- Done For Now ------------------------------------------------"
  echo -e "q) Quit"
  echo

  echo -e $YELLOW
  read -p "What would you like to do? : " CHOICE
  echo -e $BLACK

  case $CHOICE in
    1)
      installPXE
      ;;
    2)
      uninstallPXE
      ;;
    3)
      showInformationAboutPxeServer
      ;;
    4)
      changeHostname
      ;;
    5)
      identifyPis
      ;;
    6)
      getDetailsAboutPi
      ;;
    7)
      makeImage
      ;;
    8)
      deployImage
      ;;
    9)
      deleteImage
      ;;
    10)
      deleteProvisionedPi
      ;;
    q | Q)
      clear
      exit 0
      ;;
    *)
      mainMenu
    ;;
  esac
}

# This function makes an image of a Raspberry Pi from the network
makeImage(){
  # Clean the screen
  showHeader imager

  echo -e $YELLOW
  read -p " What is the IP of the Raspberry Pi to image? [e.g. 10.0.0.30] : " PIIP
  echo
  echo " Example image file names: "
  echo "    Pi-4B-Buster-Clean-Install"
  echo "    Pi-1B-Bullseye-WebServer"
  echo "    Pi-3B-Stretch-MyApp"
  echo "    Pi-Zero-Jessie-MagicMirror"
  echo
  read -p " What do you want to name the image? [e.g. See above examples] : " IMAGENAME
  while [ -d /PXE/images/boot/${IMAGENAME} ]
  do
    showHeader imager
    echo -e $RED 
    echo "   [!] - An image with that name already exists!"
    echo "   Delete previous image or choose a different name." $YELLOW
    echo
    echo " Example image file names: "
    echo "    Pi-4B-Buster-Clean-Install"
    echo "    Pi-1B-Bullseye-WebServer"
    echo "    Pi-3B-Stretch-MyApp"
    echo "    Pi-Zero-Jessie-MagicMirror"
    echo
    read -p " What do you want to name the image? [e.g. See above examples] : " IMAGENAME
  done

  
  echo -e $RED"------------------------------------------------------------------------------------------------------------------"
  echo " IN ORDER TO DO THIS, WE NEED TO LOG IN AS << ROOT >>"
  echo 
  echo " Make sure that you set a password for your root user and enable << root SSH access >> in the target Raspberry Pi"
  echo " before trying to run this."
  echo
  echo " You can do it by logging in with your regular 'pi' account and following these steps:"
  echo "   1. Change your password, running this command:"
  echo "       sudo passwd root"
  echo "   2. Edit the SSH configuration file:"
  echo "       sudo nano /etc/ssh/sshd_config"
  echo "   3. Start a search in the file by pressing [CTRL + W]"
  echo "   4. Type the following:"
  echo "      PermitRootLogin"
  echo "   5. You should see a commented line that looks like this:"
  echo "      #PermitRootLogin prohibit-password"
  echo "   6. Change it to look like this:"
  echo "      PermitRootLogin yes"
  echo "   7. Press [CTRL + X], then [y], then [Enter] to save and exit"
  echo "   8. Run this command to restart the SSH service:"
  echo "      sudo service ssh restart"
  echo
  echo " IT IS RECOMMENDED THAT YOU UNDO THESE CHANGES AFTER WE ARE DONE.  FOR SECURITY REASONS, ALLOWING ROOT SHH ACCESS"
  echo " IS HIGHLY DISCOURAGED."
  echo "------------------------------------------------------------------------------------------------------------------"
  
  promptForEnter

  showHeader imager

  echo " You will be prompted by the system to provide your << root >> password to execute the remote commands."
  echo 
  echo " Please be patient.  Copying all the files from the SD Card can take a pretty long time."
  echo " Just let it do its thing until you see the confirmation message."
  echo -e "-----------------------------------------------------------------------------------------------------------"$YELLOW
  echo

  # Check with method we are using
  CHECK=$(cat $SCRIPTPATH/RPi-PXE.conf | grep Method | awk -F ":" '{print $2}')
  # If using NAS, grab the info from the config file
  if [ $CHECK == '1' ]; then
    NFSIP=$(cat RPi-PXE.conf | grep NASIP | awk -F ":" '{print $2}')
    NFSMOUNTPOINT=$(cat RPi-PXE.conf | grep NFSMOUNT | awk -F ":" '{print $2}')
  # If using Hard Drive or SD Card
  else
    NETWORKINFO=$(ip -4 addr show dev eth0 | grep inet)
    NFSIP=$(sed -nr 's|.*inet ([^ ]+)/.*|\1|p' <<< ${NETWORKINFO})
    NFSMOUNTPOINT=/PXE
  fi

  echo "echo
        echo 'Making sure NFS Common is installed ...'
        apt-get install -y nfs-common > /dev/null

        echo
        echo 'Creating a temporary /PXE folder ...'
        if [ ! -d /PXE ]; then
          mkdir /PXE > /dev/null
        fi

        echo
        echo 'Mounting the NFS share to the /PXE folder ...'
        mount -t nfs -O proto=tcp,port=2049,rw,all_squash,anonuid=1001,anongid=1001 $NFSIP:$NFSMOUNTPOINT /PXE -vvv > /dev/null
        
        echo
        if [ ! -d /PXE/images ]; then
          echo '[!] - /PXE/images folder was not found!'
          echo 'Creating /PXE/images structure ...'
          mkdir /PXE/images > /dev/null
          mkdir /PXE/images/boot > /dev/null
          mkdir /PXE/images/filesystems > /dev/null
        fi
        
        echo
        if [ ! -d /PXE/images/boot/${IMAGENAME} ]; then
          echo 'Creating new folder for the image boot files - /PXE/images/boot/${IMAGENAME} ...'
          mkdir /PXE/images/boot/${IMAGENAME} > /dev/null
        fi

        echo
        echo 'Copying boot files ...'
        cp -r /boot/* /PXE/images/boot/${IMAGENAME}

        echo
        if [ ! -d /PXE/images/filesystems/${IMAGENAME} ]; then
          echo 'Creating new folder for the image filesystem files - /PXE/images/filesystems/${IMAGENAME} ...'
          mkdir /PXE/images/filesystems/${IMAGENAME}
        fi

        echo
        echo 'Copying system files ...'
        cd /
        rsync -xa --progress / /PXE/images/filesystems/${IMAGENAME}/ --exclude PXE
        
        echo
        echo 'Dismounting the NFS share from the /PXE folder ...'
        umount /PXE

        echo
        echo 'Deleting the temporary /PXE folder ...'
        rm -R /PXE

        echo
        echo ' A folder has been created in /PXE/images/boot/ for ${IMAGENAME}.'
        echo
        echo ' A folder has been created in /PXE/images/filesystems/ for ${IMAGENAME}.'" > script.sh
  chmod +x script.sh
  ssh root@${PIIP} 'bash -s' < script.sh
  rm script.sh

  promptForEnter
  mainMenu
}

# This function prompts for enter to continue
promptForEnter(){
  echo -e $YELLOW
  read -p " Press [Enter] to continue: "
}

# This function clears the screen and shows the header
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
  
  case $1 in
    "changeHostname")
      echo -e "║──────────────────────────────────────────────────────────────────────────────────────────────Change Hostname─║"
      ;;

    "deleteImage")
      echo -e "║──────────────────────────────────────────────────────────────────────────────────────────────Delete An Image─║"
      ;;
    "deleteProvisionedPi")
      echo -e "║──────────────────────────────────────────────────────────────────────────────────────Delete A Provisioned Pi─║"
      ;;
    "deployImage")
      echo -e "║──────────────────────────────────────────────────────────────────────────────────────────────Deploy An Image─║"
      ;;

    "imager")
      echo -e "║───────────────────────────────────────────────────────────────────────────────────────────────────────Imager─║"
      ;;

    "install")
      echo -e "║────────────────────────────────────────────────────────────────────────────────────────────────────Installer─║"
      ;;

    "networkScan")
      echo -e "║─────────────────────────────────────────────────────────────────────────────────────────────────Network Scan─║"
      ;;
    
    "otherPiDetails")
      echo -e "║────────────────────────────────────────────────────────────────────────────────────────In-Network Pi Details─║"
      ;;

    "piDetails")
      echo -e "║────────────────────────────────────────────────────────────────────────────────────────This Device's Details─║"
      ;;

    "uninstall")
      echo -e "║─────────────────────────────────────────────────────────────────────────────────────────────────Un-Installer─║"
      ;;
    
    *)
      echo -e "║────────────────────────────────────────────────────────────────────────────────────────────────────Main Menu─║"
    ;;
  esac

  echo -e "╚══════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
  echo -e "                                                                      Brought to you by Jorge Pabon (PREngineer)"
  echo
  echo -e
}

# This function shows information about the PXE Server Raspberry Pi
showInformationAboutPxeServer(){
  # Clean the screen
  showHeader piDetails

  HOSTNAME=$(hostname)
  SERIALNUMBER=$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2 | cut -c 9-16)
  ARMVERSION=$(cat /proc/cpuinfo | grep model | awk -F ": " '/model name/ {print $2}')
  MACADDRESS=$(ifconfig | grep ether | awk '{print $2}')
  # the tr part is to suppress the warning about a null byte
  PIMODEL=$(cat /sys/firmware/devicetree/base/model | tr '\0' '\n')
  OSVERSION=$(cat /etc/os-release | grep PRETTY_NAME | awk -F '"' '/PRETTY_NAME/{print $2}')
  NETWORKINFO=$(ip -4 addr show dev eth0 | grep inet)
  INET=$(sed -nr 's|.*inet ([^ ]+)/.*|\1|p' <<< ${NETWORKINFO})
  BRD=$(sed -n 's|^.*\s*brd\s\+\(\S\+\)\s.*|\1|p' <<< ${NETWORKINFO})
  GATEWAY=$(ip route | awk '/default/ {print $3}')
  DNS_SRV=${GATEWAY}
  
  echo -e $CYAN"-----------------------------------------------------------------------------------------------------------"
  echo -e "                                             Basic Information"
  echo -e "-----------------------------------------------------------------------------------------------------------"$BLACK
  echo "  Hostname: ${HOSTNAME}"
  echo "OS Version: ${OSVERSION}"
  echo -e $CYAN"-----------------------------------------------------------------------------------------------------------"
  echo -e "                                             Hardware Information"
  echo -e "-----------------------------------------------------------------------------------------------------------"$BLACK
  echo "  RPI Model: ${PIMODEL}"
  echo "   ARM Vers: ${ARMVERSION}"
  echo " Serial Num: ${SERIALNUMBER}"
  echo "Mac Address: ${MACADDRESS}"
  echo -e $CYAN"-----------------------------------------------------------------------------------------------------------"
  echo -e "                                            Network Information"
  echo -e "-----------------------------------------------------------------------------------------------------------"$BLACK
  echo "IP Address: ${INET}"
  echo "   Gateway: ${GATEWAY}"
  echo " Broadcast: ${BRD}"
  echo "DNS Server: ${DNS_SRV}"
  echo -e $CYAN"-----------------------------------------------------------------------------------------------------------"

  promptForEnter

  mainMenu
}

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

# This function is to do the installation process
uninstallPXE(){
  showHeader uninstall

  ################### Part 1 - Disable the Services ###################

  echo
  echo -e $MAGENTA "Disabling the system services ..." $BLACK
  echo
  systemctl disable dnsmasq &> /dev/null && \
  systemctl disable dnsmasq.service &> /dev/null && \
  systemctl disable rpcbind &> /dev/null && \
  systemctl disable nfs-kernel-server &> /dev/null && \
  systemctl disable systemd-networkd &> /dev/null & showSpinner
  # Check for error
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while disabling the services!" $BLACK
    exit 1
  fi

  ################### Part 2 - Delete files ###################

  echo -e $YELLOW
  echo
  read -p " Do you want to delete /PXE folder and all its files? [y/n]: " DELETEFILES
  
  # Delete files
  if [ $DELETEFILES == 'Y' ] || [ $DELETEFILES == 'y' ]; then
    echo -e $MAGENTA
    echo " Deleting /PXE and its files ..."
    if [ -d /NFSPXE ]; then
      rm -R /NFSPXE/* > /dev/null & showSpinner
    fi
    if [ -d /PXE ]; then
      rm -R /PXE/* > /dev/null & showSpinner
    fi
    echo
  fi

  # Unmount file shares from the system
  CHECK=$(cat /etc/fstab | grep /PXE)
  if [ ! -z "$CHECK" ]; then
    echo -e $MAGENTA "Unmounting /PXE ..."
    umount /PXE > /dev/null
    echo
  else
    echo -e $MAGENTA "No /PXE to unmount"
    echo
  fi  
  CHECK=$(cat /etc/fstab | grep /NFSPXE)
  if [ ! -z "$CHECK" ]; then
    echo -e $MAGENTA "Unmounting /NFSPXE mount ..."
    umount /NFSPXE > /dev/null
    echo
  else
    echo -e $MAGENTA "No /NFSPXE to unmount"
    echo
  fi  

  # Delete the /PXE folder
  if [ -d /PXE ]; then
    rm -R /PXE
  fi
  if [ -d /NFSPXE ]; then
    rm -R /NFSPXE
  fi
  rm RPi-PXE.conf
  
  # Remove the auto mount from the /etc/fstab file
  echo -e $MAGENTA
  echo " Deleting mount points from /etc/fstab ..."
  sed -i '/PXE/d' /etc/fstab
  sed -i '/# Samba/d' /etc/fstab
  sed -i '/# NFS/d' /etc/fstab
  sed -i '/NFSPXE/d' /etc/fstab

  ################### Part 3 - Remove installed packages ###################
  echo
  echo -e $MAGENTA "Removing NFS Kernel Server ..." $BLACK
  echo
  apt-get purge nfs-kernel-server -y > /dev/null & showSpinner
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while removing the NFS Kernel Server!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Removing Samba ..." $BLACK
  echo
  apt-get purge samba -y > /dev/null & showSpinner
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while removing Samba!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Removing CIFS-Utils ..." $BLACK
  echo
  apt-get purge cifs-utils -y > /dev/null & showSpinner
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while removing CIFS-Utils!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Removing DNSMasq ..." $BLACK
  echo
  apt-get purge dnsmasq -y > /dev/null & showSpinner
  # Check for error while running installation
  if [ $? -ne 0 ]; then
    echo -e $RED "[!] An error occurred while installing dnsmasq!" $BLACK
    exit 1
  fi

  echo
  echo -e $MAGENTA "Removing any other unused packages ..." $BLACK
  echo
  apt-get autoremove -y > /dev/null & showSpinner
  echo

  echo
  echo -e $RED 
  echo "-----------------------------------------------------------------------------------------------------------"
  echo -e "                      We need to restart to run cleanly!"
  echo "-----------------------------------------------------------------------------------------------------------"
  echo
  promptForEnter
  reboot now
}

################### EXECUTION ###################

# Validate that this script is run as root
if [ $(id -u) -ne 0 ]; then
  echo -e $RED "[!] Error: You must run RPI-PXE-Server as root user, like this: sudo $SCRIPTPATH/RPi-PXE.sh or sudo $0" $BLACK
  echo
  exit 1
fi

# Start with the main menu
mainMenu

exit 0