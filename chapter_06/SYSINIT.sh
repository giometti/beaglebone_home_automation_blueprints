#!/bin/bash

BIN="../bin"

set -e

$BIN/load_firmware.sh adc
$BIN/load_firmware.sh i2c

echo "done!"

exit 0
