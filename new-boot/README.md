# Please Support This Project!

I would appreciate a donation if you found it useful.

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=53CD2WNX3698E&lc=US&item_name=PREngineer&item_number=RPi-PXE%2dServer&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

You can also support me by sending a BitCoin donation to the following address:

19JXFGfRUV4NedS5tBGfJhkfRrN2EQtxVo

---

# About this Branch

This branch will be modified for use with Raspberry Pi images using the /boot/firmware format.

It broke the network boot process and people in the community are trying to figure it out.  Please, be patient while I try to find a way to get this working.

From now on, if you plan to use an old image that uses the original /boot partition, you will have to use the old-boot branch of this repository.

**If you are using a new image of the Raspbian OS (on or after bookworm), use this branch.**

## Warning

To overcome the issues brought by the new /boot partition, I am doing the following:

  1. Copying the /boot/firmware folder to the /boot folder in the NAS, as that seems to be the new location
  2. Using NFS v3 as 4+ is not supported in the Debian 12 port (bookworm) yet
  3. Attempt to fix the SSH issue (not turned on even when a file is present)

I've managed to get some Pis running relatively OK, but I've noticed that one specific kernel module fails to load.  It is the: systemd-remount-fs.service

You might also have issues if you issue the reboot command to the Pi.  If you do, you need to power cycle it.

I'll try to keep attention to the Raspberry Pi community forums for news about the issues being fixed.  If you find a post before me, I'd appreciate it if you let me know thorugh an Issue referencing the post.

---

# RPI-PXE

A PXE Server for Raspberry Pis

# About

This shell application is designed to work with all Raspberry Pi models.  It is simple and lightweight.

When installed, it will turn your Raspberry Pi into a PXE Server that will help other Raspberry Pis in your network to boot from the network.

You can choose to hold the files in:

  1. A NAS server in your network (recommended)
  2. An attached storage device in your Raspberry Pi
  3. The boot device of your Raspberry Pi (SD Card - not recommended | SATA Hard Disk - OK)



# How to Install

  * Step 1 - Clone the repository

    cd ~

    sudo git clone https://github.com/Tech-Byte-Tips/RPi-PXE
    
  * Step 2 - Run the Application

    cd ~/RPi-PXE && chmod +x RPi-PXE.sh && sudo ./RPi-PXE.sh

# License

All rights are reserved by Jorge Pabón.

Free to use for personal use.
Use of this application for commercial purposes without a license is not authorized.
For licensing costs contact Jorge Pabón at pianistapr@hotmail.com.
