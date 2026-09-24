#!/bin/bash
set -e
#VERSIONING
SCRIPT_VERSION="v1.4"
SCRIPT_UPDATE="2026-05-05"

#DESCRIPTION
# This will be used to do site-based analysis on raspberry shake instruments.
# This is very much a work in progress
USAGE_TEXT="Usage: $(basename "$0") CAPITALIZED WORD after option indicates variable to which that argument gets passed.\n\n\t\
OPTION |   ARGUMENT   | DESCRIPTION       \n\t\
-------|--------------|-------------------\n\t\
 -n    | SITE_NAME    | Name of site; this will be used as the first part of the filename; defaults to 'HVSRSite'\n\t\
 -d    | DURATION     | Duration of HVSR acquisition, in minutes (default is 20 min; up to one decimal point supported)\n\t\
 -c    | CHECK_INT    | The interval at which to check/print status, in seconds (default is 30 sec)\n\t\
 -s    | STARTUP_TIME | The amount of time between when the hvsr command is run and when data is saved, in seconds (default is 15 sec)\n\t\
 -t    |              | Run this site as a test (does not save data or turn off Shake)\n\t\
 -v    |              | Print information to terminal in verbose manner\n\t\
 -h    |              | Print this help message (-h should only be used by itself)\n\t\
 -e    | EXPORT_DISK* | EXPORT_DISK argument is optional; Export data in /opt/hvsr/data folder to inserted USB disk (experimental)\n\n"

#CODE

# ESTABLISH DEFAULT PARAMETERS
# Default variable values
SITE_NAME="HVSRSite"
DURATION=20
CHECK_INT=30
VERBOSE=""

RUN_AS_TEST=false
TEST_TEXT=""
CURR_YEAR=$(date +'%Y')
STATION=$(ls "/opt/data/archive/$CURR_YEAR/AM")
HVSR_DIR="/opt/hvsr"
HVSRDATA_DIR="/opt/hvsr/data"
EXPORT_DISK="/dev/sda1"
DO_EXPORT=true

# Time to wait for startup and powerdown at start/after end of acquisition.PDOWN_TIME Not currently used
STARTUP_TIME=15
# PDOWN_TIME=30

# Parse out help command only
if [ "$1" == "-h" ] ; then
    printf "$USAGE_TEXT"
    exit 0
fi

# READ IN OPTIONS
# Get options
while getopts 'n:td:c:s:h:ve' opt; do
    case "$opt" in
        n) SITE_NAME="$OPTARG"
            echo $SITE_NAME
            ;;
        t) RUN_AS_TEST=true
            TEST_TEXT="RUNNING SITE AS TEST (will not power off instrument)";;
        d) DURATION="$OPTARG";;
        c) CHECK_INT="$OPTARG";;
        s) STARTUP_TIME="$OPTARG";;
        v) VERBOSE="-v";;
        e)
            # Get the last USB storage device (we only have one, so should be ok?)
            # Not sure how this works, but it does
            # Check next positional parameter
            DO_EXPORT=false
	    ;;
	  \?) printf "$USAGE_TEXT" exit 1 ;;
    esac
done

# Shift the parsed options
shift "$((OPTIND - 1))"

# If the minutes entered for duration were decimal, extract each part
read mindur mindecdur <<< $(echo $DURATION | awk -F. '{print $1, $2}')
mindecdur=$(printf %.1s "$mindecdur")

# Now get the duration in seconds
S_DURATION=$(($((mindur * 60))+$((mindecdur*6))))
START_TIME=$(date -d "@$(( $(date +%s) + $STARTUP_TIME ))" +"%H:%M:%S")
START_TIMESTAMP=$(date -d "@$(( $(date +%s) + $STARTUP_TIME ))" +"%s")
END_TIMESTAMP=$(date -d "@$(( $(date +%s) + $STARTUP_TIME + $S_DURATION ))" +"%s")
END_TIME=$(date -d @"$END_TIMESTAMP" +"%H:%M:%S")

# Defaults for Latitude, longitude, and altitude
LAT="LAT_NA"
LON="LON_NA"
ALT="ALT_NA"

TPV=$(gpspipe -w -n 5 2>/dev/null | grep '"class":"TPV"' | head -n 1)

if [ -n "$TPV" ]; then
  MODE=$(echo "$TPV" | sed -n 's/.*"mode":\([0-9]\).*/\1/p')

  if [ "$MODE" -ge 2 ]; then
    LAT=$(echo "$TPV" | sed -n 's/.*"lat":\([-0-9.]*\).*/\1/p')
    LON=$(echo "$TPV" | sed -n 's/.*"lon":\([-0-9.]*\).*/\1/p')
  fi

  if [ "$MODE" -eq 3 ]; then
    ALT=$(echo "$TPV" | sed -n 's/.*"alt":\([-0-9.]*\).*/\1/p')
  fi
fi

# START HVSR PROCESS
# Print out information
echo "HVSR SCRIPT VERSION $SCRIPT_VERSION"
echo "LAST UPDATED $SCRIPT_UPDATE"
echo "$TEST_TEXT"
echo ""
echo "---------------------------------------------------------------------"
echo "                            SITE INFORMATION"
echo "---------------------------------------------------------------------"
echo "STATION             |  $STATION"
echo "SITE NAME           |  $SITE_NAME"
echo "DURATION            |  $DURATION minutes ($S_DURATION seconds)"
echo "ACQUISITION DATE    |  $(date) ($(date +"%Y-%m-%d"))"
echo "  DAY OF YEAR       |  $(date +%j)"
echo "START TIME          |  $START_TIME"
echo "END TIME            |  $END_TIME"
echo "---------------------------------------------------------------------"
echo "LONGITUDE           |  $LON"
echo "LATITUDE            |  $LAT"
echo "ELEVATION (GPS) [m] |  $ALT"
echo "---------------------------------------------------------------------"
echo ""

while [[ $STARTUP_TIME > 0 ]]; do
    echo -ne "Beginning acquisition in $STARTUP_TIME seconds \033[0K\r"
    sleep 1
    STARTUP_TIME=$(($STARTUP_TIME - 1))
done

# Set the start time as current time
START_TIME=$(date +'%Y-%m-%d %T')
START_TIMESTAMP=$(date +%s)

# End time add duration to start time
END_TIME=$(date -d "$date $S_DURATION seconds" +'%Y-%m-%d %T')
END_HOUR=$(date -d "$date $S_DURATION seconds" +'%H')
END_MIN=$(date -d "$date $S_DURATION seconds" +'%M')
END_SEC=$(date -d "$date $S_DURATION seconds" +'%S')
END_TIMESTAMP=$(date -d "$date $S_DURATION seconds" +'%s')

UTC_DIFF=$(date +%:::z)

# Print out the times of everything
echo -ne "  Acquisition start time is $(date -d "$START_TIME" +'%H:%M') (UTC $UTC_DIFF)"
echo "  End time is   $(date -d "$END_TIME" +'%H:%M') (UTC $UTC_DIFF)"
echo "  ----------------------------------------------------------------------"

# Initialize current timestamp, which will be updated every check_int interval
CURRENT_TIMESTAMP=$(date +%s)

# Loop through every CHECK_INT seconds, print progress and keep it going until we reach desired time
while [[ $CURRENT_TIMESTAMP < $END_TIMESTAMP ]]; do
    # Get the timestamp for the current time
    CURRENT_TIMESTAMP=$(date +%s)

    # Calculate time remaining
    MIN_REMAINING=$(( ($END_TIMESTAMP - $CURRENT_TIMESTAMP)/60))
    SEC_REMAINING=$(( ($END_TIMESTAMP - $CURRENT_TIMESTAMP) - ($MIN_REMAINING*60)))
    TOT_SEC_REMAINING=$(( ($END_TIMESTAMP - $CURRENT_TIMESTAMP)))
    printf "    %02d:%02d Remaining   |  CURRENT TIME: $(date +%T)  |  END TIME: $(date -d "$END_TIME" '+%T')\n" $MIN_REMAINING $SEC_REMAINING

    # Only for the last interval, where the check int is less than the total time remaining
    if [ $CHECK_INT -lt $TOT_SEC_REMAINING ]; then
        sleep $CHECK_INT
    else
        # Only sleep the amount of time left
        sleep $TOT_SEC_REMAINING
    fi
    # Get the timestamp for the current time again (to check against END_TIMESTAMP)
    CURRENT_TIMESTAMP=$(date +%s)
done

# Final printouts
echo "  ----------------------------------------------------------------------"
echo ""
echo "ACQUISITION COMPLETED!"
echo ""

# DATA CLEAN UP
echo "Cleaning up data now"

# Use slinktool to trim, combine, and export data
# First, create the directory to hold the data if it does not already exist
if [ ! -d $HVSR_DIR ]; then
    mkdir "$HVSR_DIR"
fi

if [ ! -d $HVSRDATA_DIR ]; then
    mkdir "$HVSRDATA_DIR"
fi

# Format the times to create a time window (-tw option)
sYEAR=$(date -d "$START_TIME" '+%Y')
sMON=$(date -d "$START_TIME" '+%m')
sDAY=$(date -d "$START_TIME" '+%d')
sHOUR=$(date -d "$START_TIME" '+%H')
sMIN=$(date -d "$START_TIME" '+%M')
sSEC=$(date -d "$START_TIME" '+%S')
sTIME="$sYEAR,$sMON,$sDAY,$sHOUR,$sMIN,$sSEC"

eYEAR=$(date -d "$END_TIME" '+%Y')
eMON=$(date -d "$END_TIME" '+%m')
eDAY=$(date -d "$END_TIME" '+%d')
eHOUR=$(date -d "$END_TIME" '+%H')
eMIN=$(date -d "$END_TIME" '+%M')
eSEC=$(date -d "$END_TIME" '+%S')
eTIME="$eYEAR,$eMON,$eDAY,$eHOUR,$eMIN,$eSEC"

if [ $LAT = "LAT_NA" ]; then
    LATSTR=""
else
    LATSTR="_"${LAT:0:9}"N"
fi

if [ $LON = "LON_NA" ]; then
    LONSTR=""
else
    LONSTR="_"${LON:0:9}"E"
fi

fname="$SITE_NAME"_"$STATION"_$(date -d "$START_TIME" '+%j_%Y-%m-%d_%H%M')-$(date -d "$END_TIME" '+%H%M')$LONSTR$LATSTR.mseed
fpath="$HVSRDATA_DIR/$fname"
echo "Exporting site data to  $fpath"

# slinktool will query data on shake, between start and end time, and save it as an mseed file in HVSR_DIR
slinktool -S "AM_$STATION:EH?" -tw "$sTIME:$eTIME" -o "$fpath" $VERBOSE :18000
echo "HVSR site data saved successfully to $fpath"


if "$DO_EXPORT"; then
    eval nextopt=\${$OPTIND}
    # existing or starting with dash?
    if [[ -n "$nextopt" && "$nextopt" != -* ]] ; then
        OPTIND=$((OPTIND + 1))
        level=$nextopt
    else
        level=1
    fi

    # Get specified export disk, or use last (alphabetic) detected one
    # check if disk is specified first
    if [[ -n "$nextopt" && "$nextopt" != -* ]]; then
        EXPORT_PARTITION="$nextopt"

        if ! [[ "$EXPORT_PARTITION" =~ ^[0-9]{1,3}$ ]]; then
            echo "$EXPORT_PARTITION specified as export disk"
        else
            EXPORT_DATE=$(printf "%03d" "$EXPORT_PARTITION")
            USBDISKS=$(readlink -f /dev/disk/by-id/usb*)
            EXPORT_PARTITION=$(echo "$USBDISKS" | tail -n 1)
            echo "Exporting files on USB disk detected at $EXPORT_PARTITION from day $EXPORT_DATE"
        fi

    else
        # DEFAULT: when no argument specified, find disk 
        USBDISKS=$(readlink -f /dev/disk/by-id/usb*)
        EXPORT_PARTITION=$(echo "$USBDISKS" | tail -n 1)

        if [[ -z "$EXPORT_PARTITION" || ! -b "$EXPORT_PARTITION" ]]; then
            echo "No USB disks detected. Data will not be exported to USB"
            # If not specified and not detected, do not export
            DO_EXPORT=false
        else
            echo "No export disk specified, will attempt to use USB disk detected at $EXPORT_PARTITION"
        fi
    fi
fi

# Exited out of conditional and went back in just to check that we're still good to export
# Mount drive to shake disk then export
if "$DO_EXPORT"; then
    echo "Using USB partition for export: $EXPORT_PARTITION"

    MOUNTED_DIR="/mnt/usbdrive"

    sudo mkdir -p "$MOUNTED_DIR"

    if ! sudo mount "$EXPORT_PARTITION" "$MOUNTED_DIR"; then
        echo "Failed to mount $EXPORT_PARTITION. USB export not performed"
    else

        if sudo cp "$fpath" "$MOUNTED_DIR/"; then
            sync
            echo "USB Export successful."
        else
            echo "USB copy failed."
        fi
        sudo umount "$MOUNTED_DIR"
    fi
fi

#RASPBERRY SHAKE SYSTEM CHECK HERE
# If this is being run on a raspberry shake, poweroff instrument
if ! $RUN_AS_TEST; then
    # Shutdown instrument
    echo "Powering down in 5 seconds"
    sleep 5
    sudo poweroff
else
    echo "Program Completed. If this was a not a test, your Raspbery Pi system would shut down now."
fi

echo "Program will end in 10 seconds"
sleep 10
