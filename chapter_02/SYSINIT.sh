#!/bin/bash

BIN="../bin"

# Uncomment the following in case of buggy kernel in USB host management
cat /dev/bus/usb/001/001 > /dev/null ; sleep 1

set -e

$BIN/load_firmware.sh adc

echo BB-LEDS-C2 > /sys/devices/bone_capemgr.9/slots

[ -e /dev/ttyUSB0 ] && stty -F /dev/ttyUSB0 9600

echo "done!"

exit 0
