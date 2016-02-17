#!/bin/bash

BIN="../bin"

set -e

$BIN/gpio_set.sh 68 out
$BIN/gpio_set.sh 69 out

$BIN/load_firmware.sh adc
$BIN/load_firmware.sh ttyO1

echo "done!"

exit 0
