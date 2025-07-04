"""
A simple way to read raw NMEA 0183 data from a GPS module that has I2C output capability.
Optimized for 100Hz operation with FIFO output.
"""
import os
import signal
import sys
import time
import smbus2

I2C_BUS_Value = 1
I2C_ADDRESS_Value = 0x10
FIFO_PATH = '/tmp/gpsd0'

def parse_int(val, default):
    "Parse integer from string, first as decimal then as hex"
    try:
        result = int(val)
    except (TypeError, ValueError):
        try:
            result = int(val,16)
        except (TypeError, ValueError):
            result = default
    return result

# Default to device 0-0042; can be overriden via environment
I2C_BUS = parse_int(os.environ.get("I2C_BUS", None), I2C_BUS_Value)
I2C_ADDRESS = parse_int(os.environ.get("I2C_ADDRESS", None), I2C_ADDRESS_Value)

def handle_ctrl_c(sig, frame):
    "Exit handler"
    sys.exit(130)

signal.signal(signal.SIGINT, handle_ctrl_c)

def write_to_fifo(data):
    "Write data to FIFO with proper error handling"
    try:
        # Open FIFO for each write operation - this allows gpsd to also open it
        with open(FIFO_PATH, 'w') as fifo:
            fifo.write(data + '\n')
            fifo.flush()
        return True
    except (BrokenPipeError, IOError) as e:
        # This is normal when gpsd isn't reading - don't spam stderr
        return False
    except Exception as e:
        print("FIFO write error: {}".format(e), file=sys.stderr, flush=True)
        return False

def parse_response(gps_line):
    "Parse GPS line"
    # Check #1 -- make sure line starts with $ and $ doesn't appear twice
    if len(gps_line) == 0 or gps_line[0] != 36 or gps_line.count(36) != 1:
        return
    
    # Check #2 -- 83 is maximum NMEA sentence length
    if len(gps_line) > 83:
        return
    
    # Check #3 -- make sure that only readable ASCII characters
    # and carriage return are seen
    for char in gps_line:
        if (char < 32 or char > 122) and char != 13:
            return
    
    gps_chars = ''.join(chr(char) for char in gps_line)
    
    # Check #4 -- skip txbuff allocation error
    if 'txtbuf' in gps_chars:
        return
    
    # Check #5 -- only split twice to avoid unpack error
    if "*" in gps_chars:
        gps_str, chk_sum = gps_chars.split('*', 1)
    else:
        gps_str = gps_chars
        chk_sum = "0A"
    
    # Remove the $ and do a manual checksum on the rest of the NMEA sentence
    chk_val = 0
    for char in gps_str[1:]:
        chk_val ^= ord(char)
    
    # Compare the calculated checksum with the one in the NMEA sentence
    try:
        if chk_val != int(chk_sum, 16):
            return
    except:
        return
    
    # All checks passed - write to FIFO
    write_to_fifo(gps_chars.strip())

def read_gps():
    "Read bytes from I2C device with retry logic"
    max_retries = 3
    retry_count = 0
    
    while retry_count < max_retries:
        response = []
        try:
            with smbus2.SMBus(I2C_BUS) as bus:
                while True:
                    byte = bus.read_byte(I2C_ADDRESS)
                    if byte == 255:
                        return True  # Success - no data available
                    if byte == ord('\n'):
                        break
                    response.append(byte)
                parse_response(response)
                return True  # Success
        except IOError as e:
            retry_count += 1
            print("# I2C error (attempt {}/{}): {}".format(retry_count, max_retries, e), 
                  file=sys.stderr, flush=True)
            if retry_count >= max_retries:
                return False
            time.sleep(0.01)  # Shorter retry delay
    return False

# Main loop with timing control
def main():
    target_interval = 0.01  # 100Hz = 10ms intervals
    consecutive_failures = 0
    max_consecutive_failures = 10
    
    print("# Starting GPS I2C reader, writing to {}".format(FIFO_PATH), file=sys.stderr, flush=True)
    
    while True:
        start_time = time.time()
        
        success = read_gps()
        if not success:
            consecutive_failures += 1
            if consecutive_failures >= max_consecutive_failures:
                print("# Too many consecutive I2C failures, exiting", 
                      file=sys.stderr, flush=True)
                sys.exit(1)
        else:
            consecutive_failures = 0
        
        # Maintain 100Hz timing
        elapsed = time.time() - start_time
        sleep_time = target_interval - elapsed
        if sleep_time > 0:
            time.sleep(sleep_time)

if __name__ == "__main__":
    main()
