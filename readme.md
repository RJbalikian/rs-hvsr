# RS-HVSR

This repository contains various codes and scripts for optimizing Raspberry Shakes, specifically for HVSR measurements.

The following is an explanation of the structure:
* **hvsr_script**: Directory containing current and old versions of a script enabling Raspberry Shakes to save data to a single .mseed file for HVSR analysis
* **gpsd_update**: Scripts and information on updating GPSD to work with i2c GPS chip/module

# Initial setup for HVSR Shakes

In rs.local dashboard (in a web browser):
1. Actions > Actions > Turn Offline Mode On (may require restart)
2. Actions > Actions > Change SSH Password
3. Settings > Data > Waveform Data Saving (set to something at least 60, more like 360 if large (>64gb) SD card; may require restart)

In terminal:
1. Add Wifi networks
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
2.  Edit configuration to allow ethernet and wifi:
    1.  `sudo nano /opt/settings/user/enable-wifi.conf`
    2.  If main line says `OFF`, change to `ON`
    3.  Restart shake: `sudo reboot`
3.  Turn off internal wifi
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
5.  Set up dongle (optional)
    1. With our mediatek chip, to "isntall" firmware, just move the `mt7601u.bin` file to `/lib/firmware` directory on the shake
6. Set up HVSR Script
    1. Follow instructions [here](https://github.com/RJbalikian/SPRIT-HVSR/tree/main/sprit/resources/hvsrscripts)
8. Set up GPS (optional, still working on this)
    1. Follow instructions [here](https://github.com/RJbalikian/rs-hvsr/tree/main/gpsd_update)
