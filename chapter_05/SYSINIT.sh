#!/bin/bash

BIN="../bin"

set -e

$BIN/load_firmware.sh adc

echo BB-LEDS-C5 > /sys/devices/bone_capemgr.9/slots

echo "done!"

exit 0
