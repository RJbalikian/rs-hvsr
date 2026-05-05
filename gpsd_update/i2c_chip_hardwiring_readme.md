# I2C GPS Chip Hardwiring Instructions
> The instructions here apply to the [Adafruit Mini GPS PA1010D - UART and I2C - STEMMA QT](https://www.adafruit.com/product/4415) GPS Chip, but others may also work as long as they support I2C and PPS.

# Instructions
## Setup 
You will need the following materials:
* Soldering iron, solder, flux (i.e., whatever you need for electronics soldering)
* Screwdriver for M2.5 standoffs and Shake case
* Assorted lengths of wire (small (e.g., 24 guage) for connecting chips
  * [STEMMA QT cable](https://www.adafruit.com/product/4209) works with Adafruit chip linked to above, but not necessary (one additional cable needed for PPS as well)
  * [CR1220 Battery](https://www.adafruit.com/product/380) (availble from many online retailers) also recommended with this particular chip
  * [Lab table, work stool, and intergalactic space ship optional](https://www.youtube.com/watch?v=Wxu7z7hfVns)

## Preparation
Remove enclosure lid, Shake hat (blue chip), and Shake from enclosure.

## Solder/Connect wires to GPS Chip
* FOR ADAFRUIT PA1010D ONLY: STEMMA QT Cable: According to the [pinout documentation](https://learn.adafruit.com/adafruit-mini-gps-pa1010d-module/pinouts), both plugs work with I2C outputs.
  * In their examples, however, they use the plug next to the PPS/power LEDs.
* For soldering/breadboard applications
  * Solder wires to the holes labeled "3Vo", "GND", "SCL", "SDA", and "PPS". Often, the following wire colors are used by convention:
    * 3Vo (3 volt out): Red
    * GND (Ground): Black
    * SDA (Serial Data): Blue
    * SCL (Serial clock): Gray (Yellow is used in the STEMMA QT cable)
    * PPS (Pulse per second): No color convention
* Whether soldering or plugging in, leave enough to connect to appropriate GPIO pins on Raspberry Pi with minimal slack.
  * Twisting the wires together can help with cable management
   
## Solder wires to Raspberry Pi Board (Green chip)
<img width="509" height="499" alt="Raspberry PI Pinout Diagram" src="https://github.com/user-attachments/assets/f275dd11-700b-4547-8d8b-8b73ac865fbd" />

  * When viewing the board from the top, the pins are on the right side of the Raspberry Pi board. (this is how the diagram below is laid out).
  * The [Shake hat (blue chip) does not use Pin 1, 3, or 5 even though the hat covers those pins](https://manual.raspberryshake.org/specifications.html#gpio-pins). Pin 9 is used, but it can be shared since it is ground.
    * Viewed from the top (with the pins/holes near the top of the board), these are the top pins on the left (inner) row.
    * Viewed from the bottom (with the pins/holes near the top of the board), these are the top 4 pins on the right (inner) row. (it is recommended to solder to the bottom of the board)
  * When the Raspberry Pi chip is oriented so the bottom is up and the pins/holes are on the left and far side of the board, the following pins are ordered from top to bottom and on the right row)
    * 3Vo - Pin 1 (Also called 3v3 Power)
    * SDA - Pin 3 (Also called GPIO 2)
    * SCL - Pin 5 (Also called GPIO 3)
    * GND - Pin 9 (Also called Ground)
  * You will also need to solder the PPS wire. When the Pi is oriented as above, this is the 6th pin/hole from the top on the outer row (left side):
    * PPS - Pin 12 (GPIO 18)

## Reconnect
Reconnect the Raspberry Pi (green) board to the standoffs in the enclosure. Screw in the standoffs above that. Add the Shake (blue) board on those standoffs. Before putting in the final screws through the holes in the Shake hat, there is enough clearance in the enclosure for the Adafruit Pa1010D GPS chip to be attached on top of the blue board with the same screw that connects the Shake hat to the standoffs. This allows the status LEDs to be used and prevents the chip from moving in the enclosure.


