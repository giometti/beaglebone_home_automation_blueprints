#!/bin/sh

echo 1000000 > /sys/devices/ocp.3/pwm_test_P9_22.12/duty
sleep 1
echo 2000000 > /sys/devices/ocp.3/pwm_test_P9_22.12/duty
