# RS-HVSR

This repository contains various codes and scripts for optimizing Raspberry Shakes, specifically for HVSR measurements.

The following is an explanation of the structure:
* **hvsr_script**: Directory containing current and old versions of a script enabling Raspberry Shakes to save data to a single .mseed file for HVSR analysis
* **gpsd_update**: Scripts and information on updating GPSD to work with i2c GPS chip/module

# Initial setup for HVSR Shakes

In rs.local dashboard (with Shake on network or connected to ethernet cable, put `rs.local` in a web browser):
1. Actions > Actions > Turn Offline Mode On (may require restart)
2. Actions > Actions > Change SSH Password
3. Settings > Data > Waveform Data Saving (set to something at least 60, more like 360 if large (>64gb) SD card; may require restart)

# Network configuration
Wifi is not recommended to have on during acquisition. However, you will likely need to have internet connectivity (wifi or otherwise) to set up the Shake initially. 

## Set up networks
In terminal:
1. If using wifi to set up Shake, add Wifi networks
    1. Edit WPA Supplicant to include wifi networks of interest
    2. `sudo nano /etc/wpa_supplicant/wpa_supplicant.conf`
    3. Add your information as below:
    4. ```bash
         network={
                  ssid="SSID of your wifi"
                  psk="password of your wifi"
         }
       ```
    5. Restart your shake: `sudo reboot` 
2.  Edit configuration to allow ethernet and wifi to be active at the same time (even if not using wifi):
    1.  `sudo nano /opt/settings/user/enable-wifi.conf`
    2.  If main line says `OFF`, change to `ON`
    3.  Restart shake: `sudo reboot`
3. Optional: if [setting up HVSR script](https://github.com/RJbalikian/SPRIT-HVSR/tree/main/sprit/resources/hvsrscripts) or other configuration that requires network connectivity and you need wifi, do that before turning off wifi in next steps

> NOTE: after completing Step 4 (turning off wifi), you must use an Ethernet cable to connect to the Shake via SSH)

4.  Turn off internal wifi
    1.  Disable Device tree overlay for internal wifi
        1.  `sudo nano /boot/config.txt`
        2.  Paste the following anywhere (I usually do near the top): `dtoverlay=pi3-disable-wifi`
    2.  "Blacklist" the internal wifi module
        1.  `sudo nano /etc/modprobe.d/raspi-blacklist.conf`
        2.  Add the following lines to that file:
            1.  ```bash
                blacklist brcmfmac
                blacklist brcmutil
                ````
    3. Reboot: 'sudo reboot'

# Optional set up steps
5. Set up HVSR Script (recommended for HVSR applications!)
    1. Follow instructions [here](https://github.com/RJbalikian/SPRIT-HVSR/tree/main/sprit/resources/hvsrscripts)
6.  MEDIUM DIFFICULTY, should only be done if not using USB GPS or if step 7 is also done): Set up dongle (optional, not recommended for regular use and not recommended unless setting up GPS chip)
    1. With our mediatek chip, to "install" its firmware, just move the `mt7601u.bin` file to `/lib/firmware` directory on the shake
7. ADVANCED: Set up GPS Chip (this requires purchasing a i2c compatible GPS )
    1. Follow instructions [here](https://github.com/RJbalikian/rs-hvsr/tree/main/gpsd_update)

> NOTE: with a portable PiPower module set up and a GPS chip and wifi dongle, it can help to reduce power usage from non-essential modules to prevent a boot loop. I have found the following helpful: 
> 1. Turn off Bluetooth: `sudo nano /boot/config.txt` and add the line: `dtoverlay=pi3-disable-bt`
> 2. Reduce CPU speed: `sudo nano /boot/config.txt` and add the line: `arm_freq=600` (default is 700)
> 3. Disable HDMI: Add the following line to your `/etc/rc.local` file before the `exit 0` line:
>   ```bash
>   /opt/vc/bin/tvservice -o
>   ```
