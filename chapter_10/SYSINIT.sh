#!/bin/bash

BIN="../bin"

set -e

$BIN/gpio_set.sh 44 out 1
$BIN/gpio_set.sh 45 out 1
$BIN/gpio_set.sh 68 out 1
$BIN/gpio_set.sh 69 out 1

modprobe lirc_gpio gpio_in=60

echo "done!"

exit 0
