# Setup on Raspberry Shakes

# Set up GPS Input

> These instructions and files have been testd and work provisionally with the pimoroni pa1010d GPS breakout module and SparkFun GPS Breakout - XA1110 (Qwiic). 
> These have been tested while soldered to the i2c pins simultanously with the Shake hat attached.

First, check that your I2C device is working. (if it is not, the rest of this guide will not work anyway).

You wil need to find the address of your GPS module. This may be listed in the documentation for your module.  

Otherwise, you can check the properties if your module is connected to the I²C bus, you will need to install `i2c-tools` if not already installed

```bash
sudo apt install i2c-tools
```

You can get your I2C bus using:

```i2cdetect -l```

If nothing comes up (what I got from a blank Raspberry Shake install), you may need to enable i2c:

```bash
sudo nano /boot/config.txt
```

Then add the following line:

```bash
dtparam=i2c_arm=on
```

Now, reboot (`sudo reboot`) and run ```i2cdetect -l``` again.

My results are:
``` 
i2c-1   i2c             bcm2835 (i2c@7e804000)                  I2C adapter
```
If this does not work, enter:
```bash
sudo raspi-config
```
This will pull up menu in your terminal. Go to Interface Options > I2C. Turn it on and exit the menu (you may need to click `Tab` to get to the Finish option).

The number after the dash is your bus. In my case, the bus is 1.

Now you can use  `i2cdetect -y 1` command to scan for all devices to confirm. (repalce `1` with whatever number your bus is).

```bash
i2cdetect -y 1
```
When I run this command, I get this:
```bash
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- --
10: 10 -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
```
This means my i2c address is `0x10` (column 0, row 10)

Update the following variables near the top of the file in this repository at `/gpsd_update/gpsd_i2c.py`. I have included my values below:

```python
I2C_BUS_Value = 1
I2C_ADDRESS_Value = 0x10
```

Move files to RS:

```shell
scp -r "/path/to/your/local/gpsd_update/" "myshake@rs.local:"
```

Now, ssh into RS:
```shell
ssh myshake@rs.local
```

You will be asked to enter your password:

Now we will move our files into the service directory, where they will live:

```bash
sudo mkdir /etc/systemd/system/gpsd-i2c.service.d
sudo mv gpsd_update/gpsd-i2c.service /etc/systemd/system/
sudo mv gpsd_update /etc/systemd/system/gpsd-i2c.service.d/

```

Install the necessary software (you will need to connect your Shake to internet for this):

```bashMore actions
sudo apt install socat
sudo apt install python3-pip #This will update python pip
sudo python3 -m pip install smbus2 # install smbus2
```

Set the service to start automatically on boot:

```bash
sudo systemctl enable --now gpsd-i2c.service
```

You will likely need to reset the service and deamon:

```bash
sudo systemctl start gpsd-i2c.service
sudo systemctl daemon-reload
```

Use the following command to check the status of/monitor the service:

```bash
sudo journalctl -fu gpsd-i2c.service
```

If the service starts, then you should see a new virtual serial port in `/dev/gpsd0` (use `ls /dev` and see if there is an item called `gpsd0` in the /dev directory.  You can change the name of this device, if necessary, by editing the [gpsd-i2c.service](gpsd-i2c.service) file.

Now, update the GPS defaults.

Use the following to open the gpsd defaults file for editing.

```bash 
sudo nano /etc/default/gpsd
```

Enter/paste the following:

```bash
START_DAEMON="true"
GPSD_OPTIONS="-n -G -D 2"
DEVICES="/dev/gpsd0"
USBAUTO="false"
GPSD_SOCKET="/var/run/gpsd.sock"
```

The current version of the Raspberry Shake OS will try to change this file on boot to the default value. You can prevent this (and keep your GPS working) by making the file uneditable with the following:

```bash
sudo chattr +i /etc/default/gpsd
```

(You can undo this later using the following code: `sudo chattr -i /etc/default/gpsd`)

Once you've re-configured GPSD, you can attempt to restart it:

```bash
sudo systemctl restart gpsd-i2c.service
sudo systemctl restart gpsd
```

Then check the logs to see that it's actually running:
```bash
sudo journalctl -fu gpsd
```

To ensure that the gps is reading correctly, execute either `gpsmon` (recommended) or `cgps -s` to view live data from GPSD. If using `gpsmon`, you should see NMEA sentences straming along the bottom of the terminal.

## Use PPS timing
Enable PPS in the `/boot/config.txt` by adding the following line:

```bash
dtoverlay=pps-gpio,gpiopin=18
```

Then reboot `sudo reboot`.

Ensure PPS Tools are installed:

```bash
sudo apt update
sudo apt install pps-tools
```

Check that you are getting PPS Data.
```bash
sudo ppstest /dev/pps0
```

You should get streaming output akin to this:
```bash
trying PPS source "/dev/pps0"
found PPS source "/dev/pps0"
ok, found 1 source(s), now start fetching data...
source 0 - assert 1751599342.999402435, sequence: 153 - clear  0.000000000, sequence: 0
source 0 - assert 1751599343.999398687, sequence: 154 - clear  0.000000000, sequence: 0
source 0 - assert 1751599344.999395356, sequence: 155 - clear  0.000000000, sequence: 0
source 0 - assert 1751599345.999393639, sequence: 156 - clear  0.000000000, sequence: 0
source 0 - assert 1751599346.999390048, sequence: 157 - clear  0.000000000, sequence: 0
...
```

## Update timing

It is much simpler to use `chrony` to update your time than the NTP daemon that is installed by default (at least in my experience).

To install chrony, execute the following commands (this did not work well unless I added the `--fix-missing` flag ):

```bash
sudo apt update
sudo apt install chrony --fix-missing
```
Reboot

`sudo reboot`



```bash
# Use GPS via shared memory (gpsd)
refclock SHM 0 offset 0.5 delay 0.2 refid NMEA
refclock SHM 1 offset 0.0 delay 0.2 refid PPS`
```

Restart your services
```bash
sudo systemctl restart gpsd
sudo systemctl restart chrony

```

Use the `date` command to check if the date is updating now! (it should be :) )

> NOTE: In my experience, the GPSD configuration is reset every time you reboot, so make sure to update it. I am working on a way to get this to not happen.
