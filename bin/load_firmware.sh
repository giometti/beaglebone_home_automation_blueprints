#!/bin/bash

NAME=$(basename $0)

usage() {
	echo "usage: $NAME <dev>" >&2
	exit 1
}

[ $# -lt 1 ] && usage
dev=$1

case $dev in
ttyO1|UART1)
	echo BB-UART1 > /sys/devices/bone_capemgr.9/slots
	;;

ADC|adc)
	echo cape-bone-iio > /sys/devices/bone_capemgr.9/slots
	;;

I2C|i2c)
	echo BB-I2C1 > /sys/devices/bone_capemgr.9/slots
	;;

pwm9_22)
	echo am33xx_pwm > /sys/devices/bone_capemgr.9/slots
	echo bone_pwm_P9_22 > /sys/devices/bone_capemgr.9/slots
	;;

*)
	echo "unknow device \""$dev"\"" 2>&1
	exit 1
	;;
esac

exit 0
