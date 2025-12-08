# RPI-PXE

A PXE Server for Raspberry Pis

## About This Branch

The **cli** branch contains the code for the CLI version of this application.  This was the original concept of the Raspberry Pi PXE server.

Inside, you will find 2 folders:

* **old-boot** - This folder contains the working version of the app before Raspbian Bookworm was released.  This version of the application works with any Debian-based Raspberry Pi OS before Bookworm.  The boot files were located in the /boot directory for these.

* **new-boot** - This folder contains the working version of the app after Raspbian Bookworm was released.  This version of the application works with any Debian-based Raspberry Pi OS on/after Bookworm.  The boot files were moved to the /boot/firmware directory for these.

## Please Support This Project!

I would appreciate a donation if you found it useful.

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=53CD2WNX3698E&lc=US&item_name=PREngineer&item_number=RPi-PXE%2dServer&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHosted)

You can also support me by sending a BitCoin donation to the following address:

19JXFGfRUV4NedS5tBGfJhkfRrN2EQtxVo

## About

This application is designed to work with all Raspberry Pi models.  It is simple and lightweight.

When installed, it will turn your Raspberry Pi into a PXE Server that will help other Raspberry Pis to boot from the network.

You can choose to hold the files in:

  1. An attached storage device in your Raspberry Pi
  2. A NAS server in your network (recommended)

## License

All rights are reserved by Jorge Pabón.

Free to use for personal use.
Use of this application for commercial purposes without a license is not authorized.
For licensing costs contact Jorge Pabón at pianistapr@hotmail.com.