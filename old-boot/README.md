# Please Support This Project!

I would appreciate a donation if you found it useful.

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=53CD2WNX3698E&lc=US&item_name=PREngineer&item_number=RPi-PXE%2dServer&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

You can also support me by sending a BitCoin donation to the following address:

19JXFGfRUV4NedS5tBGfJhkfRrN2EQtxVo

---

# About this Branch

This branch was created to preserve the state of the application (how it worked) before the introduction of the changes to the /boot partition by adding a /boot/firmware folder.

It broke the network boot process and people in the community are trying to figure it out.

From now on, the main branch will be adjusted to work with the latest version of the /boot partition.

**If you are using an old image of the Raspbian OS, use this branch instead.**

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
