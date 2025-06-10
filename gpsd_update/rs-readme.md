# Setup on Raspberry Shakes

# Set up GPS Input

> These instructions and files work with the pimoroni pa1010d GPS breakout module. 
> These have not been tested on the regular GPIO pins yet (just the dedicated i2c pins...with no Shake hat!)

First, check that your I2C device is working. (if it is not, the rest of this guide will not work anyway).

You wil need to find the address of your GPS module. This may be listed in the documentation for your module.  

Otherwise, you can check the properties if your module is connected to the I²C bus, you will need to install `i2c-tools` if not already installed

```sudo apt install i2c-tools ```

You can get your I2C bus using:

```i2cdetect -l```

My results are:
``` 
i2c-1   i2c             bcm2835 (i2c@7e804000)                  I2C adapter
```

The number after the dash is your bus. In my case, it is 1.

Now you can use `i2cdetect -y 1` to scan for all devices to confirm. (repalce `1` with whatever number your bus is).




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

```bash
sudo apt install python3-smbus2 socat
sudo python3 -m pip install smbus2 # Not sure if this is needed
```

Set the service to start automatically on boot:

```bash
sudo systemctl enable --now gpsd-i2c.service
```

You may need to run `sudo systemctl daemon-reload` and/or `sudo systemctl start gpsd-i2c.service` to start the service.

Use `sudo journalctl -fu gpsd-i2c.service` to monitor the service.

If the service starts, then you should see a new virtual serial port in `/dev/gpsd0`.  You can change the name of this device, if necessary, by editing the [gpsd-i2c.service](gpsd-i2c.service) file.

You can also check the GPS data using `gpsmon` or `cgps`.

Now, update the GPS defaults (the file may not exist)

Use ```sudo nano /etc/default/gpsd``` to open the file. Enter/paste the following:

```bash
START_DAEMON="true"
GPSD_OPTIONS="-n -G -D 2"
DEVICES="/dev/gpsd0"
USBAUTO="false"
GPSD_SOCKET="/var/run/gpsd.sock"
```

Once you've re-configured GPSD, you can attempt to restart it:

```bash
sudo systemctl restart gpsd-i2c.service
# Wait a couple seconds
sudo systemctl restart gpsd
```

Then check the logs to see that it's actually running:
```bash
sudo journalctl -fu gpsd
```

And as a final test, execute either `gpsmon` or `cgps -s` to view live data from GPSD.
