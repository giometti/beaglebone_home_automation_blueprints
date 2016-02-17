#!/bin/bash

BIN="../bin"

set -e

$BIN/gpio_set.sh 67 in
$BIN/gpio_set.sh 66 out 1
$BIN/gpio_set.sh 69 out 1
$BIN/gpio_set.sh 68 out 1

$BIN/load_firmware.sh pwm9_22
sleep 2
echo 0 > /sys/devices/ocp.3/pwm_test_P9_22.12/polarity
echo 20000000 > /sys/devices/ocp.3/pwm_test_P9_22.12/period
echo 2000000 > /sys/devices/ocp.3/pwm_test_P9_22.12/duty

echo BB-W1-GPIO > /sys/devices/bone_capemgr.9/slots

echo "done!"

exit 0
