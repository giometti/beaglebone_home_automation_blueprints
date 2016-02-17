#!/bin/bash

NAME=$(basename $0)
SYSFS_PATH="/sys/class/leds/c2:"

usage() {
        echo "usage: $NAME <led> -1|0|<hz>" >&2
        exit 1
}

[ $# -lt 2 ] && usage
name=$1
mode=$2

# Sanity checks
if [ ! -d "$SYSFS_PATH$name" ] ; then
	echo "$NAME: unknow led $name!" >&2
	exit 1
fi
if ! [ "$mode" -eq "$mode" ] 2>/dev/null ; then
	echo "$NAME: invalid mode parameter $mode!" >&2
	exit 1
fi
if [ "$mode" -lt -1 -o "$mode" -gt 25 ] ; then
	echo "$NAME: mode parameter must be in [-1,25]!" >&2
	exit 1
fi

# Ok, do the job

case $mode in
-1)
	# Turn on the LED
	echo none > /sys/class/leds/c2\:$name/trigger
	echo 255 > /sys/class/leds/c2\:$name/brightness
	;;

0)
	# Turn off the LED
	echo none > /sys/class/leds/c2\:$name/trigger
	echo 0 > /sys/class/leds/c2\:$name/brightness
	;;

*)
	# Flash the LED
	t=$((1000 / $mode / 2))

	echo timer > /sys/class/leds/c2\:$name/trigger
	echo $t > /sys/class/leds/c2\:$name/delay_on
	echo $t > /sys/class/leds/c2\:$name/delay_off
	;;
esac

exit 0
