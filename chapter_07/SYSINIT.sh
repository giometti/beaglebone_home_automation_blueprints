#!/bin/bash

BIN="../bin"

set -e

$BIN/load_firmware.sh adc
$BIN/load_firmware.sh i2c

echo BB-W1-GPIO > /sys/devices/bone_capemgr.9/slots

echo "done!"

exit 0
